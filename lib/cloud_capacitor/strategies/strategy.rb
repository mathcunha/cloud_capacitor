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
        return nil if capacitor.workloads.index(capacitor.current_workload) == 0
        capacitor.workloads[ capacitor.workloads.index(capacitor.current_workload) - 1 ]
      end
      
      def select_initial_configuration
        log.debug "Strategy: selecting initial configuration"
        capacitor.deployment_space.first
      end
      
      def select_lower_configuration_based_on(result)
        log.debug "Strategy: lowering configuration"
        cfgs = capacitor.deployment_space.select_lower(:price)
        cfgs.select! {|c| capacitor.unexplored_configurations.include? c}
        return nil if cfgs[0].nil?
        log.debug "Strategy: Lower config selected: #{cfgs[0]}"
        capacitor.deployment_space.pick cfgs[0].size, cfgs[0].name
      end

      def select_higher_configuration_based_on(result)
        log.debug "Strategy: raising configuration from #{capacitor.deployment_space.current_config}"
        cfgs = capacitor.deployment_space.select_higher(:price)
        cfgs.select! {|c| capacitor.unexplored_configurations.include? c}
        return nil if cfgs[0].nil?
        log.debug "Strategy: Higher config selected: #{cfgs[0]}"
        capacitor.deployment_space.current_config = cfgs[0]
      end

    end
  end
end
