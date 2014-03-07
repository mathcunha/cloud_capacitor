require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/configuration"
require_relative "cloud_capacitor/strategies/nm_strategy"
require_relative "cloud_capacitor/executors/gdrive_executor"

module CloudCapacitor
  CPU_LOAD_LIMIT = 80
  MEM_LOAD_LIMIT = 70

  class Capacitor
    attr_accessor :deployment_space, :current_config
    attr_accessor :configs_by_cpu, :configs_by_mem, :configs_by_price
    attr_accessor :sla, :delta
    attr_accessor :executor

    def initialize(executor:CloudCapacitor::Executors::GDrive_Executor.new, sla:2000, delta:0.10, file:"deployment_space.yml")

      @deployment_space = load_deployment_space_from file

      @current_config   = @deployment_space[0]
      @configs_by_cpu   = @deployment_space.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = @deployment_space.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = @deployment_space.sort { |x,y| x.price <=> y.price }
      @executor         = executor
      @sla              = sla
      @delta            = delta
    end
    
    def deployment_space=(config_list)
      @deployment_space = config_list
      @current_config   = deployment_space[0]
      @configs_by_cpu   = deployment_space.sort { |x,y| x.cpu <=> y.cpu }
      @configs_by_mem   = deployment_space.sort { |x,y| x.mem <=> y.mem }
      @configs_by_price = deployment_space.sort { |x,y| x.price <=> y.price }      
    end

    def execute(configuration:, workload:)
      @executor.run(configuration: configuration, workload: workload)
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
        raise CloudCapacitor::Err::InvalidConfigurationFileError if depl_space.reject { |x| x.instance_of? CloudCapacitor::Configuration }.size > 0
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
