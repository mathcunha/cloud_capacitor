require "spec_helper"

module CloudCapacitor
  describe Configuration do
    before :all do
      @vm01  = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
      @vm02  = VMType.new(name:"c2",cpu:2, mem:2, price:0.2)

      @config01 = CloudCapacitor::Configuration.new(vm_type: @vm01, size: 1)
      @config02 = CloudCapacitor::Configuration.new(vm_type: @vm02, size: 1)
    end
    describe "#new" do
      it "creates a Configuration" do
        @config01.should be_an_instance_of CloudCapacitor::Configuration
      end
    end
  end
end