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
    
    def run_for(*workloads)
      raise Err::NoExecutorConfiguredError if @executor.nil?
      workloads.each do |workload|
        @executor.run(configuration: @deployment_space.current_config, workload: workload)
      end
    end

  end
end
