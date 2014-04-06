require "spec_helper"

module CloudCapacitor
  describe Result do

    subject(:result) { Result.new(value: 1000, cpu: 50, mem:50) }

    it "accepts result values at initialization" do
      result.should be_an_instance_of Result
    end

    it "requires result values at initialization" do
      expect { Result.new }.to raise_error
    end

    it "returns raw values" do
      result.raw_cpu.should eql 50
      result.raw_mem.should eql 50
      result.raw_value.should eql 1000
    end

    it "returns normalized result values" do

      low = Settings.capacitor.low_deviation
      med = Settings.capacitor.medium_deviation

      result.sla=(1000 * (1 + low))
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :low, direction: :down }

      result.sla=(1000 * (1 - low) + 50)
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :low, direction: :up }

      result.sla=(1000 * (1 + med))
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :medium, direction: :down }

      result.sla=(1000 * (1 - med) + 50)
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :medium, direction: :up }

      result.sla=(1000 * (1 + med) + 100)
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :high, direction: :down }

      result.sla=(1000 * (1 - med) - 100)
      puts "SLA: #{result.sla} Result: #{result.raw_value}"
      result.value.should == { deviation: :high, direction: :up }

    end


  end
end