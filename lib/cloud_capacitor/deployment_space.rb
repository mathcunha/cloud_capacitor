module CloudCapacitor

  class DeploymentSpace
    attr_accessor :configs
    attr_reader   :current_config
    attr_accessor :configs_by_cpu, :configs_by_mem, :configs_by_price

    TRAVERSAL_MODES = [:cpu, :mem, :price]
    def initialize(file:"deployment_space.yml", configurations: [])
      
      if configurations.size > 0
        self.configs = configurations
      else
        self.configs = load_deployment_space_from file
      end
 
    end

    def configs=(config_list)
      @configs = config_list
      @current_config   = @configs[0]
      @configs_by_cpu   = @configs.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = @configs.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = @configs.sort { |x,y| x.price <=> y.price }
    end

    def pick(config_name)
      pos = @configs.index { |x| x.name == config_name }
      raise Err::InvalidConfigNameError, "Unsupported config name. #{list_supported_configs}" if pos.nil?
      @current_config = @configs[pos]
    end

    def first_config
      @configs[0]
    end

    def next_config_by(mode)
      validate_modes mode
      cfg = eval('configs_by_' + mode.to_s)[rank(@current_config, mode) + 1]
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
        eval('configs_by_' + mode.to_s)[current_pos - 1]
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
        raise Err::InvalidConfigurationFileError if depl_space.reject { |x| x.instance_of? CloudCapacitor::Configuration }.size > 0
        depl_space
      end

      def validate_modes(mode)
        raise Err::InvalidModeError, "Unsupported mode: #{mode}. Supported modes are: #{modes}" if !TRAVERSAL_MODES.include? mode
      end

      def rank(config, mode)
        validate_modes mode
        eval('configs_by_'+mode.to_s).index { |x| x.name == config.name }
      end

      def list_supported_configs
        cfgs = ""
        @configs.each { |cfg| cfgs << cfg.name + "\n" }
        "Supported configs are:\n#{cfgs}"
      end
    
  end
end