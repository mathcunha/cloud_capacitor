module CloudCapacitor
  module Strategies
    
    class Strategy
      attr_accessor :capacitor
      
      def initialize
      end

      def select_initial_workload(workload_list)
        workload_list[0]
      end
      
      def raise_workload
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) + 1 ]
      end

      def lower_workload
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) - 1 ]
      end
      
      def select_initial_configuration
        capacitor.deployment_space.first
      end
      
      def select_lower_configuration_based_on(result)
        capacitor.deployment_space.previous_config_by!(:price)
      end

      def select_higher_configuration_based_on(result)
        capacitor.deployment_space.next_config_by!(:price)
      end

    end
  end
end
