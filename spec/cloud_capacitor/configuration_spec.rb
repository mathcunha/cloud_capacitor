require "spec_helper"

describe CloudCapacitor::Configuration do
  before :all do
    @config01 = CloudCapacitor::Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
    @config02 = CloudCapacitor::Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)
  end
  describe "#new" do
    it "creates a Configuration" do
      @config01.should be_an_instance_of CloudCapacitor::Configuration
    end
  end
end