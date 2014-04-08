require "spec_helper"

module CloudCapacitor
  module Executors
    describe DefaultExecutor do
      it_behaves_like "a Performance Test Executor"
      
      subject(:executor) { described_class.new }

      it "returns a Result object from Redis" do
        redis_instance = MockRedis.new
        Redis.stub(:new).and_return { redis_instance }
        
        5.times do 
          redis_instance.lpush "results", {value: 1000, cpu: 50, mem: 50, requests: 3500, errors: 5}.to_json
        end

        vm01  = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
        config01 = Configuration.new(vm_type: vm01, size: 1)

        expect(executor.run(configuration: config01, workload: 100)).to be_an_instance_of Result
      end
    end
  end
end