require_relative "cloud_capacitor/err/invalid_config_name_error"
require_relative "cloud_capacitor/err/invalid_mode_error"
require_relative "cloud_capacitor/err/no_executor_configured_error"
require_relative "cloud_capacitor/err/no_strategy_configured_error"

require_relative "cloud_capacitor/util/logger"

require_relative "cloud_capacitor/executors/default_executor"
require_relative "cloud_capacitor/executors/dummy_executor"

require_relative "cloud_capacitor/strategies/strategy"
require_relative "cloud_capacitor/strategies/nm_strategy"

require_relative 'cloud_capacitor/settings/settings'

require_relative "cloud_capacitor/capacitor"
require_relative "cloud_capacitor/configuration"
require_relative "cloud_capacitor/deployment_space"
require_relative "cloud_capacitor/deployment_space_builder"
require_relative "cloud_capacitor/result"
require_relative "cloud_capacitor/vm_type"

module CloudCapacitor
end

capacitor = CloudCapacitor::Capacitor.new
capacitor.executor = CloudCapacitor::Executors::DummyExecutor.new
capacitor.strategy = CloudCapacitor::Strategies::NM_Strategy.new
capacitor.strategy.attitude :conservative
capacitor.run_for(100,200,300,400,500,600,700,800,900,1000)

puts "_" * 80
puts ""
puts "The selected Strategy was able to complete the assessment with #{capacitor.executions} executions.\n\n"
candidates = capacitor.candidates_for.map { |k,v| "Workload #{k}: #{v.map {|c| c.fullname}.join(", ")}" }.join("\n")
puts "Candidate configs are as follows:\n#{candidates}\n" unless candidates.empty?
puts "No configs were able to meet the SLA parameter.\n" if candidates.empty?
rejected = capacitor.rejected_for.map { |k,v| "Workload #{k}: #{v.map {|c| c.fullname}.join(", ")}" }.join("\n")
puts "Rejected configs are as follows:\n#{rejected}\n\n" unless rejected.empty?
puts "All configs were able to meet the SLA parameter.\n" if rejected.empty?