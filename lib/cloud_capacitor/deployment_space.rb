module CloudCapacitor

  class DeploymentSpace
    attr_accessor :vm_types, :vm_types_by_cpu, :vm_types_by_mem, :vm_types_by_price
    attr_accessor :max_price

    attr_reader   :graph_by_cpu, :graph_by_mem, :graph_by_price
    attr_reader   :current_config, :configs

    TRAVERSAL_MODES = [:cpu, :mem, :price]
    def initialize(file:"deployment_space_new_generation.yml", vm_types: [])
      
      if vm_types.size > 0
        self.vm_types= vm_types
      else
        self.vm_types= load_deployment_space_from file
      end

    end

    def vm_types=(vm_types_list)
      @vm_types = vm_types_list
      @vm_types_by_cpu   = @vm_types.sort { |x,y| x.cpu <=> y.cpu }
      @vm_types_by_mem   = @vm_types.sort { |x,y| x.mem <=> y.mem }
      @vm_types_by_price = @vm_types.sort { |x,y| x.price <=> y.price }
      build_graphs
    end

    def build_graphs
      DeploymentSpaceBuilder.setup(@vm_types)

      @graph_by_price = DeploymentSpaceBuilder.graph_by_price
      @graph_by_cpu   = DeploymentSpaceBuilder.graph_by_cpu
      @graph_by_mem   = DeploymentSpaceBuilder.graph_by_mem

      @configs        = DeploymentSpaceBuilder.configs_available
      @current_config = @configs[0]
    end

    def select_higher(mode, from: @current_config, step: 1)
      validate_modes mode
      return nil if @current_config.nil?

      if step == 1
        return instance_variable_get("@graph_by_#{mode}").adjacent(from, :direction=> :out).uniq
      else
        array ||= []
        l_array = instance_variable_get("@graph_by_#{mode}").adjacent(from).uniq
        l_array.each do |cfg|
          array << self.select_higher(mode, from:cfg, step:step-1)
        end
        return array
      end
    end

    def select_lower(mode, from: @current_config, step: 1)
      cfgs = prepare_selection(mode, from, step)
      cfgs.select { |c| c.method(mode).call < from.method(mode).call } unless cfgs.nil?
    end

    def select_higher(mode, from: @current_config, step: 1)
      cfgs = prepare_selection(mode, from, step)
      cfgs.select { |c| c.method(mode).call > from.method(mode).call } unless cfgs.nil?
    end

    def pick(config_size, config_name)
      pos = @configs.index { |x| x.name == config_name && x.size == config_size}
      raise Err::InvalidConfigNameError, "Unsupported config name. #{list_supported_configs}" if pos.nil?
      @current_config = @configs[pos]
    end
    
    
    def first(mode=:price)
      pick(1, @vm_types_by_price[0].name)
    end
   
    private

      def prepare_selection(mode, from, step)
        validate_modes mode
        return nil if @current_config.nil?
        adjacent_configs(mode, from, step)
      end

      def adjacent_configs(mode, from, step)
        if step == 1
          return instance_variable_get("@graph_by_#{mode}").adjacent(from).uniq
        else
          array ||= []
          l_array = instance_variable_get("@graph_by_#{mode}").adjacent(from).uniq
          l_array.each do |cfg|
            array << self.adjacent_configs(mode, cfg, step-1)
          end
          return array
        end
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
        cfgs = ""
        @configs.each { |cfg| cfgs << cfg.name + "\n" }
        "Supported configs are:\n#{cfgs}"
      end
    
  end
end
