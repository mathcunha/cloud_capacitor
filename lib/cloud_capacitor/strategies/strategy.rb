module CloudCapacitor
  module Strategies
    class Strategy
      attr_accessor :capacitor

      def initialize
        @wkl_approach = :optimistic
        @cfg_approach = :optimistic
      end

      def approach(workload:, config:)
        @wkl_approach = workload if [:optimistic, :conservative, :pessimistic, :random].include? workload
        @cfg_approach = config if [:optimistic, :conservative, :pessimistic, :random].include? config
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
        case @wkl_approach
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
        depspace = capacitor.deployment_space

        case @cfg_approach
          when :pessimistic
            depspace.last(from_category: capacitor.current_category)
          when :optimistic
            depspace.first(from_category: capacitor.current_category)
          when :conservative
            depspace.middle(from_category: capacitor.current_category)
          when :random
            depspace.random
        end
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
        case @cfg_approach
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

    end
  end
end
