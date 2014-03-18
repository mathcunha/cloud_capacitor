require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/err/no_executor_configured_error"
require_relative "cloud_capacitor/configuration"
require_relative "cloud_capacitor/deployment_space"
require_relative "cloud_capacitor/strategies/nm_strategy"
require_relative "cloud_capacitor/executors/gdrive_executor"
require 'settingslogic'

module CloudCapacitor

  class Capacitor
    attr_accessor :deployment_space, :current_config
    attr_accessor :sla, :delta
    attr_accessor :executor, :strategy

    def initialize(sla:2000, delta:0.10, file:"deployment_space.yml")

      @deployment_space = DeploymentSpace.new

      @sla              = sla
      @delta            = delta
    end
    
    def run_for(*workload_list)
      raise Err::NoExecutorConfiguredError if @executor.nil?
      raise Err::NoStrategyConfiguredError if @strategy.nil?
      raise ArgumentError if invalid_workloads?(workload_list)

      # create a copy to preserve original parameter
      @workloads = Array.new(workload_list)

      @candidates_for = Hash.new{ [] } # each key defaults to an empty array
      @explored_for   = Hash.new{ [] }

      @workloads.each do |workload|
        result = @executor.run(configuration: current_config, workload: workload)
        result.normalize!(sla: sla, delta: delta)
        if result.met?(sla)

          mark_configuration_as_candidate_for workload
          strategy.select_lower_configuration_based_on(result)

        else

          mark_configuration_as_explored_for workload
          strategy.select_higher_configuration_based_on(result)
          
        end
        
      end
      @candidates_for
    end

    def strategy=(strategy)
      @strategy = strategy
      @strategy.capacitor = self
    end

    private
      def invalid_workloads?(workloads)
        return true unless workloads.is_a? Array
        valid = true
        workloads.each { |wkl|  valid &&= wkl.is_a? Integer; valid &&= (wkl >= 0) }
        !valid
      end

      def mark_configuration_as_candidate_for(workload)
        keys = @workloads.select { |k| k <= workload }
        keys.each { |k| @candidates_for[k] <<= current_config }
      end

      def mark_configuration_as_explored_for(workload)
        keys = @workloads.select { |k| k >= workload }
        keys.each { |k| @explored_for[k] <<= current_config }
      end

      def current_config
        @deployment_space.current_config
      end
  end
end
