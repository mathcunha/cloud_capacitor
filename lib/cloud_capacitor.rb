require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/err/no_executor_configured_error"
require_relative "cloud_capacitor/err/no_strategy_configured_error"

require_relative "cloud_capacitor/util/logger"

require_relative "cloud_capacitor/executors/default_executor"
require_relative "cloud_capacitor/executors/dummy_executor"

require_relative "cloud_capacitor/strategies/strategy"
require_relative "cloud_capacitor/strategies/nm_strategy"
require_relative "cloud_capacitor/strategies/mcg_strategy"

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
# capacitor.executor = CloudCapacitor::Executors::DummyExecutor.new
# capacitor.strategy = CloudCapacitor::Strategies::MCG_Strategy.new

# capacitor.strategy.attitude :conservative
# capacitor.strategy.attitude :pessimistic
# capacitor.strategy.attitude :optimistic

# capacitor.strategy.attitude workload: :conservative, config: :optimistic
# capacitor.strategy.attitude workload: :optimistic,   config: :optimistic
# capacitor.strategy.attitude workload: :pessimistic,  config: :optimistic
# capacitor.strategy.attitude workload: :optimistic,   config: :pessimistic
# capacitor.strategy.attitude workload: :optimistic,   config: :conservative
# capacitor.strategy.attitude workload: :pessimistic,  config: :pessimistic
# capacitor.strategy.attitude workload: :pessimistic,  config: :conservative
# capacitor.strategy.attitude workload: :conservative, config: :conservative
# capacitor.strategy.attitude workload: :conservative, config: :pessimistic

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