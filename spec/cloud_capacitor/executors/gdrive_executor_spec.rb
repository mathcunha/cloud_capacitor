require "spec_helper"

describe CloudCapacitor::Executors::GDrive_Executor do
  # before :all do
  #   @executor = CloudCapacitor::Executors::GDrive_Executor.new
  #   @config01 = CloudCapacitor::Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
  # end

  it_behaves_like "a Performance Test Executor"

end