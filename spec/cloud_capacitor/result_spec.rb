require "spec_helper"

module CloudCapacitor
  describe Result do
    it "accepts result values and no options at initialization" do
      Result.new(value: 1100, cpu: 50, mem:50).should be_an_instance_of Result
    end

    it "accepts result values with options" do
      Result.new(value: 1100, cpu: 50, mem:50, normalized: true, sla: 1500, delta: 0.1).should be_an_instance_of Result
    end

    it "is created normalized only if sla and delta informed at constructor" do
      result = Result.new(value: 1100, cpu: 50, mem:50, normalized: true, sla: 1500, delta: 0.1)
      result.should be_an_instance_of Result
      result.normalized?.should eql true

      result = Result.new(value: 1100, cpu: 50, mem:50, normalized: true, sla: 1500)
      result.should be_an_instance_of Result
      result.normalized?.should eql false

      result = Result.new(value: 1100, cpu: 50, mem:50, normalized: true, delta: 0.1)
      result.should be_an_instance_of Result
      result.normalized?.should eql false
    end

    it "returns raw values when not normalized" do
      result = Result.new(value: 1100, cpu: 50, mem:50)

      result.cpu.should eql 50
      result.mem.should eql 50
      result.value.should eql 1100
    end

    it "normalizes correctly and exposes correct raw values" do
      result = Result.new(value: 1100, cpu: 50, mem:50)
      result.normalize! sla: 950, delta: 0.1 

      result.cpu.should eql :low_moderate
      result.mem.should eql :low_moderate
      result.value.should == { deviation: :large, direction: :up }

      result.raw_cpu.should eql 50
      result.raw_mem.should eql 50
      result.raw_value.should eql 1100
    end


  end
end