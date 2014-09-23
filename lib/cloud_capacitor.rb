require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/err/no_executor_configured_error"
require_relative "cloud_capacitor/err/no_strategy_configured_error"
require_relative "cloud_capacitor/err/nil_graph_root_error"

require_relative "cloud_capacitor/util/logger"

require_relative "cloud_capacitor/executors/default_executor"
require_relative "cloud_capacitor/executors/dummy_executor"

require_relative "cloud_capacitor/strategies/strategy"
require_relative "cloud_capacitor/strategies/nm_strategy"
require_relative "cloud_capacitor/strategies/mcg_strategy"

require_relative "cloud_capacitor/graphs/deployment_space_graph"

require_relative 'cloud_capacitor/settings/settings' if !defined?(Rails)

require_relative "cloud_capacitor/capacitor"
require_relative "cloud_capacitor/configuration"
require_relative "cloud_capacitor/deployment_space"
require_relative "cloud_capacitor/deployment_space_builder"
require_relative "cloud_capacitor/result"
require_relative "cloud_capacitor/vm_type"

module CloudCapacitor
end

# capacitor = CloudCapacitor::Capacitor.new
# capacitor.workloads = [100,200,300,400,500,600,700,800,900,1000]
#
# capacitor.executor = CloudCapacitor::Executors::DummyExecutor.new
# capacitor.strategy = CloudCapacitor::Strategies::MCG_Strategy.new
#
# approaches = [:optimistic, :pessimistic, :conservative, :random]
#
# approaches.each do |wkl_approach|
#   approaches.each do |config_approach|
#     capacitor.strategy.approach workload: wkl_approach, config: config_approach
#     current_workload  = capacitor.strategy.select_initial_workload
#     current_category  = capacitor.strategy.select_initial_category
#     current_capacity  = capacitor.strategy.select_initial_capacity_level
#
#     equivalent_configs = current_capacity[1]
#
#     capacitor.deployment_space.take equivalent_configs[0]
#
#     puts "Approaches -  Workload: #{wkl_approach}   Config: #{config_approach}"
#     puts "Initial workload = #{current_workload}"
#     puts "Initial category = #{current_category}"
#     puts "Capacity level = #{current_capacity[0]}"
#     puts "Capacity level configs = #{equivalent_configs.map { |c| c.fullname }}"
#     puts "Initial configuration= #{capacitor.current_config}"
#
#   end
# end
# config = capacitor.deployment_space.middle[1]

# grafo = capacitor.deployment_space.graph
# grafo.capacity_levels.each_pair do |categoria, alturas|
#   puts "Categoria #{categoria.name}"
#   alturas.each_pair do |altura, configs|
#     puts "  Altura #{altura} - #{configs.map { |c| c.fullname } }"
#   end
# end


# puts "Primeiro = #{capacitor.deployment_space.first(from:config)}"
# puts "Ultimo = #{capacitor.deployment_space.last(from:config)}"
# puts "Meio = #{capacitor.deployment_space.middle(from:config)}"


# capacitor.strategy.approach :conservative
# capacitor.strategy.approach :pessimistic
# capacitor.strategy.approach :optimistic
# capacitor.strategy.approach workload: :conservative, config: :optimistic
# capacitor.strategy.approach workload: :optimistic,   config: :optimistic
# capacitor.strategy.approach workload: :pessimistic,  config: :optimistic
# capacitor.strategy.approach workload: :optimistic,   config: :pessimistic
# capacitor.strategy.approach workload: :optimistic,   config: :conservative
# capacitor.strategy.approach workload: :pessimistic,  config: :pessimistic
# capacitor.strategy.approach workload: :pessimistic,  config: :conservative
# capacitor.strategy.approach workload: :conservative, config: :conservative
# capacitor.strategy.approach workload: :conservative, config: :pessimistic

# capacitor.run_for(100,200,300,400,500,600,700,800,900,1000)

# puts "_" * 80
# puts ""
# puts "Execution count: #{capacitor.executions} executions. Total cost: $#{capacitor.run_cost.round(3)}\n\n"
# candidates = capacitor.candidates_for.sort.map { |k,v| "Workload #{k}: #{v.sort {|x,y| x.price <=> y.price }.map {|c| c.fullname}.join(", ")}" }.join("\n\n")
# puts "Candidate configs are as follows:\n\n#{candidates}\n\n\n" unless candidates.empty?
# puts "No configs were able to meet the SLA parameter.\n" if candidates.empty?
# rejected = capacitor.rejected_for.sort.map { |k,v| "Workload #{k}: #{v.sort {|x,y| x.price <=> y.price }.map {|c| c.fullname}.join(", ")}" }.join("\n\n")
# puts "Rejected configs are as follows:\n\n#{rejected}\n\n" unless rejected.empty?
# puts "All configs were able to meet the SLA parameter.\n" if rejected.empty?