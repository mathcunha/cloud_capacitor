require "spec_helper"

module CloudCapacitor
  describe Result do

    subject(:result) { Result.new(value: 1000, cpu: 50, mem:50) }

    it "accepts result values at initialization" do
      result.should be_an_instance_of Result
    end

    it "default error count should be 0" do
      expect(result.errors).to eql 0
    end

    it "default request count should be 1" do
      expect(result.requests).to eql 1
    end

    it "requires result values at initialization" do
      expect { Result.new }.to raise_error
    end

    it "returns raw values" do
      result.raw_cpu.should eql 50
      result.raw_mem.should eql 50
      result.raw_value.should eql 1000
    end

    it "accpets values for errors and requests" do
      result.errors = 5
      result.requests = 3500
      expect(result.errors).to eql 5
      expect(result.requests).to eql 3500
    end

    it "returns normalized result values" do

      low = Settings.capacitor.low_deviation
      med = Settings.capacitor.medium_deviation

      result.sla=(1000 * (1 + low))
      result.value.should == { deviation: :low, direction: :down }

      result.sla=(1000 * (1 - low) + 50)
      result.value.should == { deviation: :low, direction: :up }

      result.sla=(1000 * (1 + med))
      result.value.should == { deviation: :medium, direction: :down }

      result.sla=(1000 * (1 - med) + 50)
      result.value.should == { deviation: :medium, direction: :up }

      result.sla=(1000 * (1 + med) + 100)
      result.value.should == { deviation: :high, direction: :down }

      result.sla=(1000 * (1 - med) - 100)
      result.value.should == { deviation: :high, direction: :up }
    end
  end
end