require "spec_helper"

module CloudCapacitor
  module Executors
    describe DummyExecutor do
      before :all do
        @executor = DummyExecutor.new
        @vm01  = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
        @config01 = CloudCapacitor::Configuration.new(vm_type: @vm01, size: 1)
      end

      it_behaves_like "a Performance Test Executor"

      it "returns a fixed result suitable only for development tests purpose" do
        @executor.run(configuration: @config01, workload: 100).should be_an_instance_of Result
      end
    end
  end
end