module CloudCapacitor
  module Strategies
    
    class Strategy
      include Log

      attr_accessor :capacitor
      
      def initialize
      end

      def select_initial_workload(workload_list)
        log.debug "Strategy: selecting initial workload"
        workload_list[0]
      end
      
      def raise_workload
        log.debug "Strategy: raising workload"
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) + 1 ]
      end

      def lower_workload
        log.debug "Strategy: lowering workload"
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) - 1 ]
      end
      
      def select_initial_configuration
        log.debug "Strategy: selecting initial configuration"
        capacitor.deployment_space.first
      end
      
      def select_lower_configuration_based_on(result)
        log.debug "Strategy: lowering configuration"
        capacitor.deployment_space.select_lower(:price)
      end

      def select_higher_configuration_based_on(result)
        log.debug "Strategy: raising configuration"
        capacitor.deployment_space.select_higher(:price)
      end

    end
  end
end
