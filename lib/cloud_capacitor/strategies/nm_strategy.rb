module CloudCapacitor
  module Strategies
    class NM_Strategy < Strategy
      attr_accessor :attitude

    	def initialize
    		super
    		@attitude = :optimistic
    	end
    	def attitude(att)
    		@attitude = att if [:optimistic, :conservative, :pessimistic].include? att
    	end

      def select_initial_workload(workload_list)
        # log.debug "Strategy: Selecting initial workload with #{@attitude} attitude"
        case @attitude
        when :pessimistic
          workload_list.first
        when :optimistic
          workload_list.last
        when :conservative
          workload_list[workload_list.size / 2]
        end
      end

    end
  end
end
