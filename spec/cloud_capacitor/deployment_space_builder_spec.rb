require "spec_helper"

module CloudCapacitor
  describe DeploymentSpaceBuilder do
    before :all do
      @vm_types = [ VMType.new(name:"c1",cpu:1, mem:1, price:0.1),
                    VMType.new(name:"c2",cpu:2, mem:2, price:0.2) ]
      DeploymentSpaceBuilder.setup(@vm_types)                    
    end

    describe "#setup" do
      it "sets up minimum required data for the builder to work" do
        expect(described_class.max_price).to be_a Float
        expect(described_class.max_num_instances).to be_a Fixnum
        expect(described_class.configs_available).to be_a Array
        expect(described_class.configs_available).to have_at_least(1).configuration
      end
    end

    DeploymentSpace::TRAVERSAL_MODES.each do |mode| 
      it "can generate DeploymentSpace graphs based on Configuration attributes" do
        described_class.should respond_to("graph_by_#{mode}")
        described_class.method("graph_by_#{mode}").call.should be_a Plexus::DirectedPseudoGraph
      end
    end
  end
end
