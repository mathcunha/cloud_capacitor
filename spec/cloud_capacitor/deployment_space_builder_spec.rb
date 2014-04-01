require "spec_helper"

module CloudCapacitor
  describe DeploymentSpaceBuilder do
    before :all do
      @vm_types = [ VMType.new(name:"c1",cpu:1, mem:1, price:0.1),
                    VMType.new(name:"c2",cpu:2, mem:2, price:0.2),
                    VMType.new(name:"c3",cpu:3, mem:3, price:0.3),      
                    VMType.new(name:"c4",cpu:4, mem:4, price:0.4) ]
    end

    subject { DeploymentSpaceBuilder.graph_by_mem([]) }
    it "validates if the class is already set up" do
      expect { subject }.to raise_error
    end

    describe "#setup" do
      it "sets up minimum required data for the builder to work" do
        DeploymentSpaceBuilder.setup(@vm_types)
        expect(DeploymentSpaceBuilder.max_price).to be_a Float
        expect(DeploymentSpaceBuilder.max_num_instances).to be_a Fixnum
        expect(DeploymentSpaceBuilder.configs_available).to be_a Array
        expect(DeploymentSpaceBuilder.configs_available).to have_at_least(1).configuration
      end
    end

    DeploymentSpace::TRAVERSAL_MODES.each do |mode| 
      it "can generate DeploymentSpace graphs based on Configuration attributes" do
        described_class.should respond_to("graph_by_"+mode.to_s).with(3).arguments
      end
    end
  end
end
