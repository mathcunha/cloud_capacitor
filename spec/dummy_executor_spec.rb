require "spec_helper"

module CloudCapacitor
  module Executors
    describe DummyExecutor do
      before :all do
        @executor = DummyExecutor.new
        @config01 = CloudCapacitor::Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
      end

      it_behaves_like "a Performance Test Executor"

      it "returns a fixed result suitable only for development tests purpose" do
        @executor.run(configuration: @config01, workload: 100).should be_an_instance_of Hash
      end
    end
  end
end