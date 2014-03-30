module CloudCapacitor
  module Strategies
    
    class NM_Strategy
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
        capacitor.deployment_space.first_config
      end
      
      def select_lower_configuration_based_on(result)
      end

      def select_higher_configuration_based_on(result)
      end

# The code below will soon be transported into Capacitor as asked by issue #1 at Github
      def best_configuration_for(workload:)
        @configurations = Array.new(@capacitor.deployment_space)
        eval_performance(workload)
        @capacitor.current_config
      end

      protected
        def eval_performance(workload)
          candidates = []
          rejected   = []
          stop = false

          while !stop && !@configurations.empty? do 
            result = @capacitor.execute(configuration: @capacitor.current_config, workload: workload)

            delta = eval_response_delta result
            cpu_usage = eval_cpu result
            mem_usage = eval_mem result

            puts ""
            puts "Delta: #{delta}"
            puts "CPU: #{cpu_usage}"
            puts "Mem: #{mem_usage}"

            # puts "Deveria deletar #{@capacitor.current_config.name}"
            @configurations.delete_if {|cfg| cfg.name == @capacitor.current_config.name}
            if delta[:direction] == :up
              rejected << @capacitor.current_config
          
              if delta[:deviation] == :small
                if cpu_usage == :high && mem_usage == :low_moderate
                  @capacitor.next_config_by! :cpu
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  @capacitor.next_config_by! :mem
                elsif cpu_usage == :high && mem_usage == :high
                  stop = raise_config_cpu_and_mem.nil?
                else
                  stop = true
                end
              elsif delta[:deviation] == :medium
                # Advances twice if there are sufficient configs remaining
                if cpu_usage == :high && mem_usage == :low_moderate
                  @capacitor.next_config_by! :cpu if @capacitor.next_config_by! :cpu
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  @capacitor.next_config_by! :mem if @capacitor.next_config_by! :mem
                elsif cpu_usage == :high && mem_usage == :high
                  # here we only increase once because the increment may already be enough
                  stop = raise_config_cpu_and_mem.nil?
                else
                  stop = true
                end
              else # deviation = :large
                # Advances 3x if there are sufficient configs remaining
                if cpu_usage == :high && mem_usage == :low_moderate
                  if @capacitor.next_config_by! :cpu
                    @capacitor.next_config_by! :cpu if @capacitor.next_config_by! :cpu
                  end
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  if @capacitor.next_config_by! :mem
                    @capacitor.next_config_by! :mem if @capacitor.next_config_by! :mem
                  end
                elsif cpu_usage == :high && mem_usage == :high
                  # here we only increase once because the increment may already be enough
                  stop = raise_config_cpu_and_mem.nil?
                else
                  stop = true
                end
              end
                  
            else # direction down
              candidates << @capacitor.current_config

              if delta[:deviation] == :small
                if cpu_usage == :high && mem_usage == :low_moderate
                  @capacitor.previous_config_by! :mem
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  @capacitor.previous_config_by! :cpu
                elsif cpu_usage == :low_moderate && mem_usage == :low_moderate
                  stop = lower_config_cpu_and_mem.nil?
                else
                  stop = true
                end
              elsif delta[:deviation] == :medium
                if cpu_usage == :high && mem_usage == :low_moderate
                  @capacitor.previous_config_by! :mem if @capacitor.previous_config_by! :mem
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  @capacitor.previous_config_by! :cpu if @capacitor.previous_config_by! :cpu
                elsif cpu_usage == :low_moderate && mem_usage == :low_moderate
                  lower_config_cpu_and_mem
                else
                  stop = true
                end
              else # deviation large
                if cpu_usage == :high && mem_usage == :low_moderate
                  if @capacitor.previous_config_by! :mem
                    @capacitor.previous_config_by! :mem if @capacitor.previous_config_by! :mem
                  end
                elsif cpu_usage == :low_moderate && mem_usage == :high
                  if @capacitor.previous_config_by! :cpu
                    @capacitor.previous_config_by! :cpu if @capacitor.previous_config_by! :cpu
                  end
                elsif cpu_usage == :low_moderate && mem_usage == :low_moderate
                  stop = lower_config_cpu_and_mem.nil?
                else
                  stop = true
                end
              end
            end
            puts ""
            puts "Lista de configuracoes disponiveis"
            @configurations.each { |cfg| puts cfg.name }
            puts "Lista de configuracoes candidatas"
            candidates.each { |cfg| puts cfg.name }
            puts "Lista de configuracoes rejeitadas"
            rejected.each { |cfg| puts cfg.name }

          end
        end

        def eval_response_delta(result)
          response = result[:response_time]

          diff = (response.to_f - @capacitor.sla.to_f) / @capacitor.sla
          if diff < 0
            direction = :down
          else
            direction = :up
          end

          return {deviation: :small,  direction: direction}  if diff.abs <= (@capacitor.delta / 2)
          return {deviation: :medium, direction: direction} if diff.abs <= @capacitor.delta
          return {deviation: :large,  direction: direction}
        end

        def eval_cpu(result)
          return :high  if result[:cpu] > CloudCapacitor::CPU_LOAD_LIMIT
          return :low_moderate
        end

        def eval_mem(result)
          return :high  if result[:mem] > CloudCapacitor::MEM_LOAD_LIMIT
          return :low_moderate
        end

      private
        def raise_config_cpu_and_mem
          next_cfg_cpu = @capacitor.next_config_by :cpu
          # we need the next config with higher CPU that has also higher mem
          while next_cfg_cpu && 
                next_cfg_cpu.mem <= @capacitor.current_config.mem do
            rejected << next_cfg_cpu
            @configurations.delete_if {|cfg| cfg.eql? next_cfg_cpu}
            next_cfg_cpu = @capacitor.next_config_by :cpu
          end
          @capacitor.pick(next_cfg_cpu) if next_cfg_cpu
          next_cfg_cpu
        end

        def lower_config_cpu_and_mem
          prev_cfg_cpu = @capacitor.previous_config_by :cpu
          # we need the prev config with higher CPU that has also higher mem
          while prev_cfg_cpu && 
                prev_cfg_cpu.mem <= @capacitor.current_config.mem do
            rejected << prev_cfg_cpu
            @configurations.delete_if {|cfg| cfg.eql? prev_cfg_cpu}
            prev_cfg_cpu = @capacitor.previous_config_by :cpu
          end
          @capacitor.pick(prev_cfg_cpu) if prev_cfg_cpu
          prev_cfg_cpu
        end

    end
  end
end
