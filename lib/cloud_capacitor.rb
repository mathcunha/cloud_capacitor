require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/err/no_executor_configured_error"
require_relative "cloud_capacitor/configuration"
require_relative "cloud_capacitor/vm_type"
require_relative "cloud_capacitor/deployment_space"
require_relative "cloud_capacitor/strategies/strategy"
require_relative "cloud_capacitor/strategies/nm_strategy"
require_relative "cloud_capacitor/executors/gdrive_executor"
require 'settingslogic'

module CloudCapacitor

  class Capacitor
    attr_accessor :deployment_space, :current_config
    attr_accessor :sla, :delta
    attr_accessor :executor, :strategy
    attr_reader   :current_workload, :workloads

    def initialize(sla:2000, delta:0.10, file:"deployment_space.yml")

      @deployment_space = DeploymentSpace.new

      @sla              = sla
      @delta            = delta
      
      @current_workload = nil
      
    end
    
    def run_for(*workload_list)
      raise Err::NoExecutorConfiguredError if @executor.nil?
      raise Err::NoStrategyConfiguredError if @strategy.nil?
      raise ArgumentError if invalid_workloads?(workload_list)

      # create a copy to preserve original parameter
      @workloads = Array.new(workload_list)

      @candidates_for = Hash.new{ [] } # each key defaults to an empty array
      @rejected_for   = Hash.new{ [] }
      @executed_for    = Hash.new{ [] }

      stop = false
      
      @strategy.select_initial_configuration
      @current_workload = @strategy.select_initial_workload(workload_list)
      
      while !stop do
        
        result = @executor.run(configuration: current_config, workload: @current_workload)
        result.normalize!(sla: sla, delta: delta)

        @executed_for[@current_workload] <<= current_config

        if result.met?(sla)

          mark_configuration_as_candidate_for @current_workload
          next_config = strategy.select_lower_configuration_based_on(result)
          
          @current_workload = strategy.raise_workload if next_config.nil?

        else

          mark_configuration_as_rejected_for @current_workload
          next_config = strategy.select_higher_configuration_based_on(result)

          @current_workload = strategy.lower_workload if next_config.nil?

        end
        
        stop = next_config.nil? && @current_workload.nil?
        
      end
      @current_workload = nil
      @candidates_for
    end

    def strategy=(strategy)
      @strategy = strategy
      @strategy.capacitor = self
    end

    def unexplored_configurations
      @deployment_space.configs - (@candidates_for[@current_workload] + @rejected_for[@current_workload]).uniq
    end

    def unexplored_workloads
      unexplored = @workloads - @rejected_for.select {|_,v| v.include? @current_config }.keys
      unexplored = unexplored - @candidates_for.select {|_,v| v.include? @current_config }.keys
      unexplored
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

      def mark_configuration_as_rejected_for(workload)
        keys = @workloads.select { |k| k >= workload }
        keys.each { |k| @rejected_for[k] <<= current_config }
      end

      def current_config
        @deployment_space.current_config
      end
  end
end
