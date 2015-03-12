module CloudCapacitor
  module Strategies
    class Strategy
      attr_accessor :capacitor

      def initialize
        @wkl_approach = :optimistic
        @cfg_approach = :optimistic
      end

      def approach(workload:, config:)
        @wkl_approach = workload if [:optimistic, :conservative, :pessimistic, :random, :hybrid].include? workload
        @cfg_approach = config if [:optimistic, :conservative, :pessimistic, :random, :hybrid].include? config
      end

      def validate_approach(mode)
        if (@wkl_approach == :hybrid || @cfg_approach == :hybrid)
		return false if (mode != :mem && mode != :cpu)
	end
	return true
      end

      def select_initial_category
        capacitor.current_category = capacitor.deployment_space.graph.categories[0]
      end

      def select_initial_workload
        select_workload capacitor.workloads
      end

      def raise_workload
        unexplored = capacitor.unexplored_workloads_for(capacitor.current_config)
        unexplored = unexplored.reject { |w| w <= capacitor.current_workload }.sort!
        select_workload unexplored
      end

      def lower_workload
        unexplored = capacitor.unexplored_workloads_for(capacitor.current_config)
        unexplored = unexplored.reject { |w| w >= capacitor.current_workload }.sort!
        select_workload unexplored
      end

      def select_workload(workload_list)
	local_approach = @wkl_approach
	local_approach = hybrid_select() if local_approach == :hybrid
        case local_approach
          when :pessimistic
            workload_list.first
          when :optimistic
            workload_list.last
          when :conservative
            workload_list[workload_list.size / 2]
          when :random
            workload_list.sample
        end
      end

      def select_initial_capacity_level
        take_a_capacity_level_from(unexplored_capacity_levels)
      end

      def unexplored_capacity_levels(workload: capacitor.current_workload, category: capacitor.current_category)
        return Hash.new {[]} if workload.nil?
        return Hash.new {[]} if category.nil?
        graph = capacitor.deployment_space.graph
        levels = graph.capacity_levels[category]

        unexplored_configs = capacitor.unexplored_configurations(workload: workload)
        unexplored_levels = Hash.new {[]}

        levels.each_pair do |level, configs|
          unexplored_levels[level] = configs.select { |c| unexplored_configs.include? c }
        end

        unexplored_levels.delete_if { |level, configs| configs.empty? }
      end

      def select_lower_capacity_level
        unexplored_levels = unexplored_capacity_levels.select { |level, _| level < capacitor.current_config.capacity_level }
        take_a_capacity_level_from(unexplored_levels)
      end

      def select_higher_capacity_level
        unexplored_levels = unexplored_capacity_levels.select { |level, _| level > capacitor.current_config.capacity_level }
        take_a_capacity_level_from(unexplored_levels)
      end

      def take_a_capacity_level_from(unexplored_levels)
        levels = unexplored_levels.keys
        return [] if levels.empty?
	local_approach = @cfg_approach
	local_approach = hybrid_select() if local_approach == :hybrid
        case local_approach
          when :pessimistic
            unexplored_levels.assoc(levels[-1])
          when :optimistic
            unexplored_levels.assoc(levels[0])
          when :conservative
            unexplored_levels.assoc(levels[levels.size / 2])
          when :random
            unexplored_levels.assoc(levels.sample)
        end
      end

      def hybrid_select()
	 #puts "#{capacitor.deployment_space.mode} - [#{capacitor.current_result.cpu}, #{capacitor.current_result.mem}]" unless capacitor.current_result.nil?
	 return :conservative if capacitor.current_result.nil?
	 
	 usage = capacitor.current_result.method(capacitor.deployment_space.mode).call
	 return :optimistic if usage == :low
	 return :conservative if usage == :moderate
	 return :pessimistic if usage == :high
      end

    end
  end
end
