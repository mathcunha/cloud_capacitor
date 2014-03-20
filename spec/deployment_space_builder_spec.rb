require "spec_helper"

module CloudCapacitor
  describe DeploymentSpaceBuilder do
    DeploymentSpace::TRAVERSAL_MODES.each do |mode| 
      it "can generate DeploymentSpace graphs based on Configuration attributes" do
        described_class.should respond_to("graph_by_"+mode.to_s).with(3).arguments
      end
    end
  end
end
