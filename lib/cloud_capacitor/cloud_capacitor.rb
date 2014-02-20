require_relative "version"
require_relative "err/invalid_config_name_error"
require_relative "err/invalid_mode_error"

module CloudCapacitor
  class CloudCapacitor
    attr_accessor :deployment_space, :current_config
    attr_accessor :configs_by_cpu, :configs_by_mem, :configs_by_price
    attr_accessor :sla, :delta

    CPU_LOAD_LIMIT = 80
    MEM_LOAD_LIMIT = 70

    def initialize(sla:2000, delta:0.10, file:"deployment_space.yml")

      @deployment_space = load_deployment_space_from file

      @current_config   = @deployment_space[0]
      @configs_by_cpu   = @deployment_space.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = @deployment_space.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = @deployment_space.sort { |x,y| x.price <=> y.price }
      @sla = sla
      @delta = delta
    end
    
    def deployment_space=(config_list)
      @deployment_space = config_list
      @current_config   = deployment_space[0]
      @configs_by_cpu   = deployment_space.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = deployment_space.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = deployment_space.sort { |x,y| x.price <=> y.price }      
    end

    def execute
      #TODO
    end

    def pick(config_name)
      pos = deployment_space.index { |x| x.name == config_name }
      raise Err::InvalidConfigNameError, "Unsupported config name. #{list_supported_configs}" if pos.nil?
      @current_config = deployment_space[pos]
    end

    def eval_delta(result)
      puts sla
      puts sla.to_f

      diff = ((result.to_f - sla.to_f).abs) / sla
      
      puts "Informed result: #{result} - SLA: #{sla} - Diff: #{diff}"
      return :small  if diff <= (delta / 2)
      return :medium if diff <= delta
      return :large
    end

    def eval_cpu(result_cpu_load)
      return :high  if result_cpu_load > CPU_LOAD_LIMIT
      return :low_moderate
    end

    def eval_mem(result_mem_load)
      return :high  if result_mem_load > MEM_LOAD_LIMIT
      return :low_moderate
    end

    def next_config_by(mode)
      validate_modes mode
      cfg = eval('configs_by_' + mode.to_s)[rank(@current_config, mode) + 1]
      @current_config = cfg if cfg
      cfg
    end

    def previous_config_by(mode)
      validate_modes mode
      current_pos = rank(@current_config, mode)
      if current_pos > 0
        @current_config = eval('configs_by_' + mode.to_s)[current_pos - 1]
      else
        nil
      end
    end

    protected
      def load_deployment_space_from(file)
        depl_space = []
        File.open file do |f|
          depl_space = YAML::load( f.read )
        end
        raise Err::InvalidConfigurationFileError if depl_space.reject { |x| x.instance_of? Configuration }.size > 0
        depl_space
      end

      def validate_modes(mode)
        modes = [:cpu, :mem, :price]
        raise Err::InvalidModeError, "Unsupported mode: #{mode}. Supported modes are: #{modes}" if !modes.include? mode
      end

      def rank(config, mode)
        validate_modes mode
        eval('configs_by_'+mode.to_s).index { |x| x.name == config.name }
      end

      def list_supported_configs
        configs = ""
        @deployment_space.each { |cfg| configs << cfg.name + "\n" }
        "Supported configs are:\n#{configs}"
      end
  end
end
