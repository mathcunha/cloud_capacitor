module CloudCapacitor

  class Capacitor
    include Log

    attr_accessor :deployment_space
    attr_accessor :executor, :strategy
    attr_reader   :current_workload, :workloads
    attr_reader   :candidates_for, :rejected_for, :executed_for, :executions

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

      stop = false
      
      @strategy.select_initial_configuration
      @current_workload = @strategy.select_initial_workload(workload_list)
      log.debug "Strategy: Initial workload set to #{@current_workload}"

      while !stop do

        result = @executor.run(configuration: current_config, workload: @current_workload)
        @executions += 1

        @executed_for[@current_workload]<<= current_config

        if result.met_sla?

          mark_configuration_as_candidate_for @current_workload
          next_config = select_lower_configuration(result)
          
          previous_workload = @current_workload
          @current_workload = strategy.raise_workload if next_config.nil?

          # If achieved a dead-end, then try to escape the other way
          if @current_workload.nil? && next_config.nil?
            @current_workload = previous_workload
            next_config = select_higher_configuration(result)
            @current_workload = nil if next_config.nil?
          end

        else

          mark_configuration_as_rejected_for @current_workload
          next_config = select_higher_configuration(result)

          previous_workload = @current_workload
          @current_workload = strategy.lower_workload if next_config.nil?

          # If achieved a dead-end, then try to escape the other way
          if @current_workload.nil? && next_config.nil?
            @current_workload = previous_workload
            next_config = select_lower_configuration(result)
            @current_workload = nil if next_config.nil?
          end

        end

        log.debug "Capacitor: next_config = #{next_config}"
        stop = next_config.nil? && @current_workload.nil?
        
      end
      @current_workload = nil
      @candidates_for
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

    private
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
        cfgs[0]
      end

      def invalid_workloads?(workloads)
        return true unless workloads.is_a? Array
        valid = true
        workloads.each { |wkl|  valid &&= wkl.is_a? Integer; valid &&= (wkl >= 0) }
        !valid
      end

      def mark_configuration_as_candidate_for(workload)
        keys = @workloads.select { |k| k <= workload }
        keys.each { |k| @candidates_for[k] <<= current_config unless @candidates_for[k].include?(current_config) }
        higher_configs = deployment_space.configs.select { |cfg| cfg > current_config }
        @candidates_for[workload] += higher_configs
        @candidates_for[workload].uniq!
      end

      def mark_configuration_as_rejected_for(workload)
        keys = @workloads.select { |k| k >= workload }
        keys.each { |k| @rejected_for[k] <<= current_config unless @rejected_for[k].include?(current_config) }
        lower_configs = deployment_space.configs.select { |cfg| cfg < current_config }
        @rejected_for[workload] += lower_configs
        @rejected_for[workload].uniq!
      end

      def current_config
        @deployment_space.current_config
      end

      def update_current_config(config)
        @deployment_space.pick config.size, config.name
      end
  end
end
