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
#
# capacitor.executor = CloudCapacitor::Executors::DummyExecutor.new
# capacitor.strategy = CloudCapacitor::Strategies::MCG_Strategy.new
# workloads = [100,200,300,400,500,600,700,800,900,1000]
# approaches = [:optimistic, :pessimistic, :conservative, :random]
# slas = (1..10).map{|i| i * 10_000}
#
# heuristic_name = { optimistic:
#                        { optimistic:   "OO",
#                          pessimistic:  "OP",
#                          conservative: "OC",
#                          random:       "OR" },
#                    pessimistic:
#                        { optimistic:   "PO",
#                          pessimistic:  "PP",
#                          conservative: "PC",
#                          random:       "PR" },
#                    conservative:
#                        { optimistic:   "CO",
#                          pessimistic:  "CP",
#                          conservative: "CC",
#                          random:       "CR" },
#                    random:
#                        { optimistic:   "RO",
#                          pessimistic:  "RP",
#                          conservative: "RC",
#                          random:       "RR" }
# }
#
# approaches.each do |wkl_approach|
#   approaches.each do |config_approach|
#
#     heuristic = heuristic_name[wkl_approach][config_approach]
#
#     File.open("#{heuristic}_heuristic_result.csv", "wt") do |result|
#
#       result.puts "heuristic,workload,configuration,metsla,sla,predict" #.split(",")
#
#       slas.each do |sla|
#         CloudCapacitor::Settings.capacitor["sla"] = sla
#
#         capacitor.strategy.approach workload: wkl_approach, config: config_approach
#
#         puts "Running: Heuristic = #{heuristic} and SLA = #{sla}"
#         capacitor.run_for(*workloads)
#         puts "Run finished! Writing output"
#
#         full_trace = capacitor.results_trace
#
#         workloads.each do |w|
#           # Format: {"1.m3_medium": {100: {met_sla: false, executed: true, execution: 1}}}
#           full_trace.keys.each do |cfg|
#             exec = full_trace[cfg][w]
#             exec.nil? || exec == {} ? metsla  = nil : metsla  = exec[:met_sla]
#             exec.nil? || exec == {} ? predict = nil : predict = !exec[:executed]
#             result.puts "#{heuristic},#{w},#{cfg},#{metsla},#{sla},#{predict}" #.split(",")
#           end
#         end
#
#       end
#
#     end
#   end
# end

# grafo = capacitor.deployment_space.graph
# grafo.capacity_levels.each_pair do |categoria, alturas|
#   puts "Categoria #{categoria.name}"
#   alturas.each_pair do |altura, configs|
#     puts "  Altura #{altura} - #{configs.map { |c| c.fullname } }"
#   end
# end


# puts "_" * 80
# puts ""
# puts "Execution count: #{capacitor.executions} executions. Total cost: $#{capacitor.run_cost.round(3)}\n\n"
# candidates = capacitor.candidates_for.sort.map { |k,v| "Workload #{k}: #{v.sort {|x,y| x.price <=> y.price }.map {|c| c.fullname}.join(", ")}" }.join("\n\n")
# puts "Candidate configs are as follows:\n\n#{candidates}\n\n\n" unless candidates.empty?
# puts "No configs were able to meet the SLA parameter.\n" if candidates.empty?
# rejected = capacitor.rejected_for.sort.map { |k,v| "Workload #{k}: #{v.sort {|x,y| x.price <=> y.price }.map {|c| c.fullname}.join(", ")}" }.join("\n\n")
# puts "Rejected configs are as follows:\n\n#{rejected}\n\n" unless rejected.empty?
# puts "All configs were able to meet the SLA parameter.\n" if rejected.empty?