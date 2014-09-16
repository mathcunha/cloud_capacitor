module CloudCapacitor
  module Strategies
    class MCG_Strategy < Strategy
      attr_accessor :attitude

    	def initialize
    		super
    		@wkl_attitude = :optimistic
        @cfg_attitude = :optimistic
    	end

    	def attitude(workload:, config:)
        @wkl_attitude = workload if [:optimistic, :conservative, :pessimistic].include? workload
    		@cfg_attitude = config if [:optimistic, :conservative, :pessimistic].include? config
    	end

      def select_initial_workload(workload_list)
        log.debug "Strategy: Selecting initial workload with #{@wkl_attitude} attitude"
        case @wkl_attitude
        when :pessimistic
          workload_list.first
        when :optimistic
          workload_list.last
        when :conservative
          workload_list[workload_list.size / 2]
        end
      end

      def select_initial_configuration
        log.debug "Strategy: Selecting initial configuration with #{@cfg_attitude} attitude"
        case @cfg_attitude
        when :pessimistic
          capacitor.deployment_space.last
        when :optimistic
          capacitor.deployment_space.first
        when :conservative
          capacitor.deployment_space.middle
        end
        log.debug "Strategy: Initial configuration set to #{capacitor.deployment_space.current_config}"
      end

    end
  end
end
