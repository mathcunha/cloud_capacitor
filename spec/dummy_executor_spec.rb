require "spec_helper"

describe CloudCapacitor::Executors::Dummy_Executor do
  before :all do
    @executor = CloudCapacitor::Executors::Dummy_Executor.new
    @config01 = CloudCapacitor::Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
  end

  it_behaves_like "a Performance Test Executor"

  it "returns a fixed result suitable only for development tests purpose" do
    @executor.run(configuration: @config01, workload: 100).should eql( {response_time: 500, cpu: 45.5, mem: 38.9, errors: 0, requests: 1000} )
  end

end