require "spec_helper"

module CloudCapacitor
  describe Configuration do
    before :all do
      @vm01  = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
      @vm02  = VMType.new(name:"c2",cpu:2, mem:2, price:0.2)

      @config01_01 = Configuration.new(vm_type: @vm01, size: 1)
      @config01_02 = Configuration.new(vm_type: @vm01, size: 2)
      @config02_01 = Configuration.new(vm_type: @vm02, size: 1)
      @config02_02 = Configuration.new(vm_type: @vm02, size: 2)
    end
    describe "#new" do
      it "creates a Configuration" do
        @config01_01.should be_an_instance_of Configuration
        @config02_02.should be_an_instance_of Configuration
      end
    end

    it "compares with <" do
      @config01_01.should_not < @config01_01
      @config01_01.should <   @config01_02
    end
    it "compares with >" do
      @config01_01.should_not > @config01_01
      @config01_02.should >   @config01_01
    end
    it "compares with <=" do
      @config01_01.should <= @config01_01
      @config01_01.should <=  @config01_02
      @config01_02.should_not <=  @config01_01
    end
    it "compares with >=" do
      @config01_02.should >=  @config01_02
      @config01_02.should >=  @config01_02
      @config01_01.should_not >=  @config01_02
    end
    it "compares with ==" do
      @config01_01.should ==  @config01_01
      @config01_01.should_not ==  @config01_02
    end
    it "compares with eql?" do
      @config01_01.should eql @config01_01
      @config01_01.should_not eql @config01_02
    end
  end
end