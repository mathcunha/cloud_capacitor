module CloudCapacitor
  module Strategies
    
    class Strategy
      include Log

      attr_accessor :capacitor
      
      def initialize
      end

      def select_initial_workload(workload_list)
        # log.debug "Strategy: Initial workload set to #{workload_list[0]}"
        workload_list[0]
      end
      
      def raise_workload
        unexplored = capacitor.unexplored_workloads.reject { |w| w <= capacitor.current_workload }.sort!
        # log.debug "Strategy: raising workload from #{capacitor.current_workload} to #{unexplored.first}"
        unexplored.first
      end

      def lower_workload
        unexplored = capacitor.unexplored_workloads.reject { |w| w >= capacitor.current_workload }.sort!
        # log.debug "Strategy: lowering workload from #{capacitor.current_workload} to #{unexplored.last}"
        unexplored.last
      end
      
      def select_initial_configuration
        capacitor.deployment_space.first
        # log.debug "Strategy: Initial configuration set to #{capacitor.deployment_space.current_config}"
      end
      
      def select_lower_configurations_based_on(result)
        # log.debug "Strategy: lowering configuration from #{capacitor.deployment_space.current_config}"
        cfgs = capacitor.deployment_space.select_lower(:price)
      end

      def select_higher_configurations_based_on(result)
        # log.debug "Strategy: raising configuration from #{capacitor.deployment_space.current_config}"
        cfgs = capacitor.deployment_space.select_higher(:price)
      end

    end
  end
end
