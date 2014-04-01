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

      @configs        = DeploymentSpaceBuilder.configs_available
      @current_config = @configs[0]

    end

    def build_graphs
      DeploymentSpaceBuilder.setup(@vm_types)

      @graph_by_price = DeploymentSpaceBuilder.graph_by_price(vm_types:vm_types)
      @graph_by_cpu   = DeploymentSpaceBuilder.graph_by_cpu(vm_types:vm_types)
      @graph_by_mem   = DeploymentSpaceBuilder.graph_by_mem(vm_types:vm_types)

    end

    def next(mode, current_config:@current_config, step:1)
      array = []
      for i in 1..step
        if(current_config.nil?)
          nil
        else
          l_array =  self.instance_variable_get("@graph_by_#{mode}").adjacent(current_config) unless current_config.nil?
          l_array.each do |_config|
            if(_config.method(mode).call() > current_config.method(mode).call())
              array << _config
            end
          end
        end
      end
      if array.include?(nil)
        nil
      else
        array
      end
    end

    def previous(mode, current_config:@current_config, step:1)
      array = []
      for i in 1..step
        if(current_config.nil?)
          nil
        else
          l_array =  self.instance_variable_get("@graph_by_#{mode}").adjacent(current_config) unless current_config.nil?
          l_array.each do |_config|
            if(_config.method(mode).call() < current_config.method(mode).call())
              array << _config
            end
          end
        end
      end
      if array.include?(nil)
        nil
      else
        array
      end
    end

    def vm_types=(vm_types_list)
      @vm_types = vm_types_list
      @vm_types_by_cpu   = @vm_types.sort { |x,y| x.cpu <=> y.cpu }
      @vm_types_by_mem   = @vm_types.sort { |x,y| x.mem <=> y.mem }
      @vm_types_by_price = @vm_types.sort { |x,y| x.price <=> y.price }
      build_graphs
    end

    def pick(config_size, config_name)
      pos = @configs.index { |x| x.name == config_name && x.size == config_size}
      raise Err::InvalidConfigNameError, "Unsupported config name. #{list_supported_configs}" if pos.nil?
      @current_config = @configs[pos]
    end

    def first_config
      @configs[0]
    end

    def next_config_by(mode)
      validate_modes mode
      cfg = eval("configs_by_#{mode}")[rank(@current_config, mode) + 1]
    end

    def next_config_by!(mode)
      cfg = next_config_by mode
      @current_config = cfg if cfg
      cfg
    end

    def previous_config_by(mode)
      validate_modes mode
      current_pos = rank(@current_config, mode)
      if current_pos > 0
        eval("configs_by_#{mode}")[current_pos - 1]
      else
        nil
      end
    end

    def previous_config_by!(mode)
      validate_modes mode
      cfg = previous_config_by mode
      @current_config = cfg if cfg
      cfg
    end
    
    protected
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
