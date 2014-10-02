module CloudCapacitor

  class Capacitor
    include Log

    attr_accessor :deployment_space
    attr_accessor :executor, :strategy
    attr_accessor :current_workload, :workloads, :current_category
    attr_reader   :candidates_for, :candidates, :rejected_for, :executed_for, :current_config
    attr_reader   :executions, :run_cost, :execution_trace, :results_trace

    def initialize(mode=:strict)
      # mode = :strict
      # mode = :price if Settings.deployment_space.use_strict_comparison_mode == 0

      @deployment_space = DeploymentSpace.new mode: mode
      @executor = Executors::DefaultExecutor.new
    end
    
    def run_for(*workload_list)
      raise Err::NoExecutorConfiguredError if @executor.nil?
      raise Err::NoStrategyConfiguredError if @strategy.nil?
      raise ArgumentError if invalid_workloads?(workload_list)
      
      @workloads = Array.new(workload_list)

      @candidates_for = Hash.new{ [] } # each key defaults to an empty array
      @rejected_for   = Hash.new{ [] }
      @executed_for   = Hash.new{ [] }

      #How many times the choosen Strategy leads to invocation of the Executor
      @executions = 0
      #The total cost of tbe Strategy invocations of the Executor
      @run_cost = 0.0
      stop = false
      
      # @execution_trace[@executions] = {config:current_config, workload:@current_workload, met_sla: result.met_sla?}
      # Format: {1: config: <Configuration instance>1.m3_medium, workload: 100, met_sla: true}
      @execution_trace = Hash.new{{}}
      
      # Filled in mark_configuration_as_candidate_for 
      # and mark_configuration_as_rejected_for
      # Format: {"1.m3_medium": {100: {met_sla: false, executed: true, execution: 1}}}
      @results_trace   = Hash.new{{}}
      deployment_space.configs_by_price.map do |c| 
        @results_trace[c.fullname] = Hash.new {}
        workload_list.map { |w| @results_trace[c.fullname].update({ w => Hash.new {} }) }
      end
      
      @current_workload = @strategy.select_initial_workload
      @current_category = @strategy.select_initial_category
      @current_capacity = @strategy.select_initial_capacity_level

      equivalent_configs = @current_capacity[1]

      next_config = nil
      update_current_config equivalent_configs[0]

      while !stop do

        result = @executor.run(configuration: current_config, workload: @current_workload)
        @executions += 1
        @run_cost += current_config.price

        @executed_for[@current_workload]<<= current_config
        @execution_trace[@executions] = {config:current_config, workload:@current_workload, met_sla: result.met_sla?}

        mark_candidates_for @current_workload if result.met_sla?
        mark_rejected_for @current_workload unless result.met_sla?

        equivalent_configs.delete current_config unless equivalent_configs.nil?

        next_config = equivalent_configs.delete_at(0) unless equivalent_configs.nil?

        if next_config.nil?
          equivalent_configs = select_lower_capacity_level if result.met_sla?
          equivalent_configs = select_higher_capacity_level unless result.met_sla?
          next_config = equivalent_configs.delete_at(0) unless equivalent_configs.nil?
        end

        if next_config.nil?
          equivalent_configs = jump_to_another_category
          next_config = equivalent_configs[0] unless equivalent_configs.nil?
        end

        if next_config.nil?
          @current_workload = @strategy.raise_workload if result.met_sla?
          @current_workload = @strategy.lower_workload unless result.met_sla?
          equivalent_configs = filter_explored deployment_space.capacity_level(current_config)
          next_config = equivalent_configs[0] unless equivalent_configs.nil?
        end

        if next_config.nil? && @current_workload.nil?
# byebug
          @current_workload = @strategy.select_workload(unexplored_workloads_for)

          categs = @deployment_space.graph.categories
          unexplored_categories = categs.reject {|cat| @strategy.unexplored_capacity_levels(category: cat) == {} }
          @current_category = unexplored_categories[0]

          levels = @strategy.unexplored_capacity_levels
          @current_capacity = @strategy.take_a_capacity_level_from( levels )

          equivalent_configs = @current_capacity[1]
          next_config = equivalent_configs[0] unless equivalent_configs.nil?
        end

        update_current_config next_config unless next_config.nil?

        stop = next_config.nil? && @current_workload.nil?
        
      end
      candidates
    end

    def strategy=(strategy)
      @strategy = strategy
      @strategy.capacitor = self
    end

    def unexplored_configurations(workload: @current_workload)
      return [] if workload.nil?
      cfgs = @deployment_space.configs - (@candidates_for[workload] | @rejected_for[workload])
      # log.debug "Unexplored configs for workload #{@current_workload}:\n#{cfgs.map { |cfg| cfg.fullname }}"
      cfgs
    end

    def all_unexplored_workloads
      unexplored = @workloads.select { |w| (@rejected_for[w] | @candidates_for[w]).size < @deployment_space.configs.size }
      unexplored.sort!
    end

    def unexplored_workloads_for(config=nil)
      return all_unexplored_workloads if config.nil?
      unexplored = @workloads - (@rejected_for.select {|_,v| v.include? current_config }.keys | @candidates_for.select {|_,v| v.include? current_config }.keys)
      # unexplored = unexplored - @candidates_for.select {|_,v| v.include? current_config }.keys
      unexplored.sort!
    end

    def candidates
      # candidate_configs = {}
      # @candidates_for.each_pair do |w, cfgs|
      #   price = cfgs.sort { |x,y| x.price <=> y.price }[0].price
      #   log.debug "Menor preco das candidatas para #{w} usuarios: #{price}"
      #   candidate_configs[w] = cfgs.select { |c| c.price == price }
      # end
      # candidate_configs
      @candidates_for
    end

    def run_cost
      @run_cost
    end

    def current_config
      @deployment_space.current_config
    end

    private
      def jump_to_another_category
        # Searches for a category with unexplored configs
        #  other than the current category
        categories = @deployment_space.graph.categories.reject{|c| c.name == current_config.category}
        other_categories = categories.reject { |c| @strategy.unexplored_capacity_levels(category: c).empty? }

        # Select an unexplored capacity level from the new category
        unless other_categories.empty?
          @current_category = other_categories[0]
          levels = @strategy.unexplored_capacity_levels(category: @current_category)
          @current_capacity = @strategy.take_a_capacity_level_from( levels )
          return nil if @current_capacity.nil?
          @current_capacity[1]
        end
      end

      def select_lower_capacity_level
        @current_capacity = @strategy.select_lower_capacity_level
        # log.debug "Selectin lower capacity"
        configs_from_capacity_level @current_capacity
      end

      def select_higher_capacity_level
        @current_capacity = @strategy.select_higher_capacity_level
        # log.debug "Selectin higher capacity"
        configs_from_capacity_level @current_capacity
      end

      def configs_from_capacity_level(capacity)
        unless capacity.nil? || capacity.empty?
          # log.debug "Capacity level = #{capacity}"
          update_current_config capacity[1][0]
          return capacity[1]
        end
      end

      def filter_explored(config_list)
        return nil if config_list.nil?
        unexplored = unexplored_configurations
        config_list.select {|c| unexplored.include? c}
      end

      def invalid_workloads?(workloads)
        return true unless workloads.is_a? Array
        valid = true
        workloads.each { |wkl|  valid &&= wkl.is_a? Integer; valid &&= (wkl >= 0) }
        !valid
      end

      def mark_candidates_for(workload)
        keys = @workloads.select { |k| k <= workload }
        configs = deployment_space.eager_adjacent_configs(direction: :up)

        keys.each do |k| 
          configs.each do |cfg|
            @candidates_for[k] <<= cfg unless @candidates_for[k].include?(cfg)
            @results_trace[cfg.fullname][k].
              update({met_sla: true, executed: false, execution: @executions}) { |key, old, new| old }
          end
          @candidates_for[k].uniq!
        end
        @results_trace[current_config.fullname][workload].
          update({met_sla: true, executed: true, execution: @executions}) { |key, old, new| new }
      end

      def mark_rejected_for(workload)
        keys = @workloads.select { |k| k >= workload }
        configs = deployment_space.eager_adjacent_configs(direction: :down)

        keys.each do |k| 
          configs.each do |cfg|
            @rejected_for[k] <<= cfg unless @rejected_for[k].include?(cfg)
            @results_trace[cfg.fullname][k].
              update({met_sla: false, executed: false, execution: @executions}) { |key, old, new| old }
          end
          @rejected_for[k].uniq!
        end
        @results_trace[current_config.fullname][workload].
          update({met_sla: false, executed: true, execution: @executions}) { |key, old, new| new }
      end

      def update_current_config(config)
        @deployment_space.take config
      end
  end
end
