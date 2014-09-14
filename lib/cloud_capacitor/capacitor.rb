module CloudCapacitor

  class Capacitor
    include Log

    attr_accessor :deployment_space
    attr_accessor :executor, :strategy
    attr_reader   :current_workload, :workloads
    attr_reader   :candidates_for, :candidates, :rejected_for, :executed_for
    attr_reader   :executions, :run_cost, :execution_trace, :results_trace

    def initialize
      @deployment_space = DeploymentSpace.new
      @executor = Executors::DefaultExecutor.new
    end
    
    def run_for(*workload_list)
      raise Err::NoExecutorConfiguredError if @executor.nil?
      raise Err::NoStrategyConfiguredError if @strategy.nil?
      raise ArgumentError if invalid_workloads?(workload_list)
      
      # create a copy to preserve original parameter
      @workloads = Array.new(workload_list)

      @candidates_for = Hash.new{ [] } # each key defaults to an empty array
      @rejected_for   = Hash.new{ [] }
      @executed_for   = Hash.new{ [] }

      #How many times the choosen Strategy leads to invocation of the Executor
      @executions = 0
      #The total cost of tbe Strategy invocations of the Executor
      @run_cost = 0.0
      stop = false
      
      @strategy.select_initial_configuration
      @current_workload = @strategy.select_initial_workload(workload_list)
      # log.debug "Strategy: Initial workload set to #{@current_workload}"

      # @execution_trace[@executions] = {config:current_config, workload:@current_workload, met_sla: result.met_sla?}
      # Format: {1: config: <Configuration instance>1.m3_medium, workload: 100, met_sla: true}
      @execution_trace = Hash.new{{}}
      
      # Filled in mark_configuration_as_candidate_for 
      # and mark_configuration_as_rejected_for
      # Format: {1.m3_medium: {100: {met_sla: false, executed: true, execution: 1}}}
      @results_trace   = Hash.new{{}}
      deployment_space.configs_by_price.map do |c| 
        @results_trace[c.fullname] = Hash.new {}
        workload_list.map { |w| @results_trace[c.fullname].update({ w => Hash.new {} }) }
      end
      
      equivalent_configs = []

      while !stop do

        result = @executor.run(configuration: current_config, workload: @current_workload)
        @executions += 1
        @run_cost += current_config.price

        @executed_for[@current_workload]<<= current_config
        @execution_trace[@executions] = {config:current_config, workload:@current_workload, met_sla: result.met_sla?}

        if result.met_sla?

          mark_configuration_as_candidate_for @current_workload

          # If tested config met the SLA we give up the equivalent ones
          #   there is no point in trying more expensive
          #   equivalent capacity configs. 
          #   So, we try a lower capacity (maybe cheaper) one
          equivalent_configs = select_lower_configuration(result) 

          # Take the cheapest (list is sorted by price)
          #  and remove it from the equivalent list
          next_config = equivalent_configs.delete_at(0)
          
          # If no unexplored lower configs, then try other category
          # branch in the Development Space
          if next_config.nil?
            next_config = jump_to_another_category
          end

          # If there is no unexplored config to try,
          #   let's raise the workload level
          if next_config.nil?
            previous_workload = @current_workload
            @current_workload = strategy.raise_workload
          end

        else

          mark_configuration_as_rejected_for @current_workload

          equivalent_configs = filter_explored(equivalent_configs)
          next_config = equivalent_configs.delete_at(0)

          # If there is no unexplored equivalent config,
          #   then try a higher capacity one (take the cheapest)
          if next_config.nil?
            next_config = select_higher_configuration(result)[0]
          end

          # If no unexplored higher configs, then try other category
          # branch in the Development Space
          if next_config.nil?
            next_config = jump_to_another_category
          end

          # If there is no unexplored config to try,
          #   let's lower the workload level
          if next_config.nil?
            previous_workload = @current_workload
            @current_workload = strategy.lower_workload
          end

        end

        # log.debug "Capacitor: next_config = #{next_config}"
        stop = next_config.nil? && @current_workload.nil?
        
      end
      @current_workload = nil
      candidates
    end

    def strategy=(strategy)
      @strategy = strategy
      @strategy.capacitor = self
    end

    def unexplored_configurations
      cfgs = @deployment_space.configs - (@candidates_for[@current_workload] | @rejected_for[@current_workload])
      # log.debug "Unexplored configs for workload #{@current_workload}:\n#{cfgs.map { |cfg| cfg.fullname }}"
      cfgs
    end

    def unexplored_workloads
      unexplored = @workloads - (@rejected_for.select {|_,v| v.include? current_config }.keys | @candidates_for.select {|_,v| v.include? current_config }.keys)
      # unexplored = unexplored - @candidates_for.select {|_,v| v.include? current_config }.keys
      unexplored.sort!
    end

    def candidates
      candidate_configs = {}
      @candidates_for.each_pair do |w, cfgs|
        price = cfgs.sort { |x,y| x.price <=> y.price }[0].price
        log.debug "Menor preco das candidatas para #{w} usuarios: #{price}"
        candidate_configs[w] = cfgs.select { |c| c.price == price }
      end
      candidate_configs
    end

    def run_cost
      @run_cost
    end

    private
      def jump_to_another_category
        # Searches for a config from another category
        #  looking for the first unexplored config in all categories
        #  other than the current one
        other_categories = deployment_space.categories.reject { |c| c == current_config.category }
        other_categories.each do |other_category|
          cfgs = filter_explored deployment_space.select_category(other_category)
          unless cfgs.empty?
            return update_current_config cfgs[0]
          end
        end
        # If no unexplored configs found in a different category...
        return nil
      end

      def select_lower_configuration(result)
        filter_explored strategy.select_lower_configurations_based_on(result)
      end

      def select_higher_configuration(result)
        filter_explored strategy.select_higher_configurations_based_on(result)
      end

      def filter_explored(config_list)
        return nil if config_list.nil?
        cfgs = config_list.select {|c| unexplored_configurations.include? c}
        update_current_config cfgs[0] unless cfgs[0].nil?
        cfgs
      end

      def invalid_workloads?(workloads)
        return true unless workloads.is_a? Array
        valid = true
        workloads.each { |wkl|  valid &&= wkl.is_a? Integer; valid &&= (wkl >= 0) }
        !valid
      end

      def mark_configuration_as_candidate_for(workload)
        keys = @workloads.select { |k| k <= workload }
        configs = deployment_space.configs.select { |cfg| cfg > current_config }
        configs << current_config

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

      def mark_configuration_as_rejected_for(workload)
        keys = @workloads.select { |k| k >= workload }
        configs = deployment_space.configs.select { |cfg| cfg < current_config }
        configs << current_config

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

      def current_config
        @deployment_space.current_config
      end

      def update_current_config(config)
        @deployment_space.pick config.size, config.name
      end
  end
end
