module CloudCapacitor
  module Strategies
    
    class Strategy
      include Log

      attr_accessor :capacitor
      
      def initialize
      end

      def select_initial_workload(workload_list)
        log.debug "Strategy: Initial workload set to #{workload_list[0]}"
        workload_list[0]
      end
      
      def raise_workload
        log.debug "Strategy: raising workload"
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) + 1 ]
      end

      def lower_workload
        log.debug "Strategy: lowering workload"
        return nil if capacitor.workloads.index(capacitor.current_workload) == 0
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) - 1 ]
      end
      
      def select_initial_configuration
        capacitor.deployment_space.first
        log.debug "Strategy: Initial configuration set to #{capacitor.deployment_space.current_config}"
      end
      
      def select_lower_configurations_based_on(result)
        log.debug "Strategy: lowering configuration from #{capacitor.deployment_space.current_config}"
        cfgs = capacitor.deployment_space.select_lower(:price)
      end

      def select_higher_configurations_based_on(result)
        log.debug "Strategy: raising configuration from #{capacitor.deployment_space.current_config}"
        cfgs = capacitor.deployment_space.select_higher(:price)
      end

    end
  end
end
