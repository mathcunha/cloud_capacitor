require 'plexus/dot'

module CloudCapacitor

  class DeploymentSpace
    include Log

    attr_accessor :vm_types, :vm_types_by_cpu, :vm_types_by_mem, :vm_types_by_price
    attr_accessor :current_config, :max_price, :root

    attr_reader   :graph, :mode
    attr_reader   :graph_by_cpu, :graph_by_mem, :graph_by_price
    attr_reader   :configs, :categories, :configs_by_price, :strict_graph

    DEFAULT_DEPLOYMENT_SPACE_FILE = File.join( File.expand_path('../../..', __FILE__), "wordpress_deployment_space.yml" )
    TRAVERSAL_MODES = [:cpu, :mem, :price, :strict]
    
    def initialize(mode: :strict, file:DEFAULT_DEPLOYMENT_SPACE_FILE, vm_types: [])
      @mode = mode
      if vm_types.size > 0
        self.vm_types = vm_types
      else
        self.vm_types = load_deployment_space_from file
      end

    end

    def vm_types=(vm_types_list)
      @vm_types = vm_types_list
      build_deployment_space
    end

    def build_deployment_space
      @vm_types_by_cpu   = @vm_types.sort { |x,y| x.cpu <=> y.cpu }
      @vm_types_by_mem   = @vm_types.sort { |x,y| x.mem <=> y.mem }
      @vm_types_by_price = @vm_types.sort { |x,y| x.price <=> y.price }
      log.debug "Initializing deployment space with these vms:\n#{@vm_types_by_price.map { |vm| vm.name }}"

      log.debug "Setting up Deployment Space Builder..."
      DeploymentSpaceBuilder.setup(@vm_types)

      log.debug "Building deployment space graphs"
      build_graph

      @configs = DeploymentSpaceBuilder.configs_available

      @configs_by_cpu   = @configs.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = @configs.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = @configs.sort { |x,y| x.price <=> y.price }
      # log.debug "Deployment space complete with these configs:\n#{@configs_by_price.map { |cfg| cfg.fullname }}"
      @current_config = @configs[0]
    end

    def build_graph
      @root = DeploymentSpaceBuilder.create_root_node
      # log.debug "Generating graph by #{@mode} mode"
      @graph = DeploymentSpaceBuilder.graph(root, @mode)
      # @graph.write_to_graphic_file('jpg','#{@mode}_graph')
    end
    
    def take(config)
      @current_config = config unless @configs.index(config).nil?
    end

    def pick(config_size, config_name)
      raise Err::InvalidConfigNameError, "Unsupported config name. #{list_supported_configs}" if @vm_types.select {|vm| vm.name == config_name }.size == 0
      raise Err::InvalidConfigNameError, "Invalid config size. Maximum # of instances is #{Settings.deployment_space.max_num_instances}" if config_size > Settings.deployment_space.max_num_instances
      pos = @configs.index { |x| x.name == config_name && x.size == config_size}
      @current_config = @configs[pos]
      @current_config
    end

    def random(from_category:@graph.categories[0])
      height = @graph.capacity_levels[from_category].keys.sample
      @graph.capacity_levels[from_category].assoc(height)
    end

    def first(from_category:@graph.categories[0])
      raise ArgumentError unless from_category.respond_to?(:fullname) && from_category.size == 0
      @graph.capacity_levels[from_category].assoc(1)
    end

    def last(from_category:@graph.categories[0])
      raise ArgumentError unless from_category.respond_to?(:fullname) && from_category.size == 0
      last_height = @graph.capacity_levels[from_category].keys[-1]
      @graph.capacity_levels[from_category].assoc(last_height)
    end

    def middle(from_category:@graph.categories[0])
      raise ArgumentError unless from_category.respond_to?(:fullname) && from_category.size == 0
      last_height = @graph.capacity_levels[from_category].keys[-1]
      @graph.capacity_levels[from_category].assoc(last_height / 2)
    end

    def categories
      DeploymentSpaceBuilder.categories
    end

    def capacity_levels
      @graph.capacity_levels
    end

    def capacity_level(config)
      category = DeploymentSpaceBuilder.create_fake_node(config.category)
      @graph.capacity_levels[category][config.capacity_level]
    end

    def select_category(category, cfg_list=nil)
      list = cfg_list.nil? ? @configs : cfg_list
      return list if category.nil?
      list.select { |cfg| cfg.category == category }
    end

    def eager_adjacent_configs(mode: @mode, from: @current_config, direction: :up)
      validate_modes mode
      raise ArgumentError, "Invalid direction. Valid ones are: :up, :down" unless [:up, :down].include? direction
      return nil if from.nil?

      from = [from]
      cfgs = from
      adjacent = from[0]
      while from.size > 0
        cfgs_temp = []
        from.each do |source|
          adjacent = graph.adjacent(source)
          unless adjacent.nil?
            # Get rid of fake nodes like root and categories
            adjacent.select! { |c| c.size > 0 }
            if strict_mode?
              adjacent.select! { |c| c > source  || source.size == 0} if direction == :up
              adjacent.select! { |c| c < source  || source.size == 0} if direction == :down
            else
              adjacent.select! { |c| c.method(mode).call > source.method(mode).call } if direction == :up
              adjacent.select! { |c| c.method(mode).call < source.method(mode).call } if direction == :down
            end
            cfgs_temp += adjacent
          end
        end
        from = cfgs_temp.uniq
        cfgs += from
      end
      cfgs.uniq.sort { |x,y| x.price <=> y.price }
    end

    private
    def strict_mode?
        Settings.deployment_space.use_strict_comparison_mode == 1
      end


      def load_deployment_space_from(file)
        depl_space = []
        File.open file do |f|
          depl_space = YAML::load( f.read )
        end
        raise Err::InvalidConfigurationFileError if depl_space.reject { |x| x.instance_of? CloudCapacitor::VMType }.size > 0
        depl_space
      end

      def validate_modes(mode)
        raise Err::InvalidModeError, "Unsupported mode: #{mode}. Supported modes are: #{modes}" if !TRAVERSAL_MODES.include? mode
      end

      def rank(config, mode)
        validate_modes mode
        eval("configs_by_#{mode}").index { |x| x.name == config.name }
      end

      def list_supported_configs
        vms = ""
        @vm_types.each { |vm| vms << vm.name + "\n" }
        "Supported configs are:\n#{vms}"
      end
    
  end
end
