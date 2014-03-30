# These are shared examples[1] to test different Performance Assessment Strategies
# for the contracted bahavior of using a reference to a Capacitor to execute tests
# over the SUT (System Under Test) and to respond with the best Configuration 
# suitable to run the SUT under the specified workload.
#
# [1] https://www.relishapp.com/rspec/rspec-core/v/2-14/docs/example-groups/shared-examples
module CloudCapacitor
  shared_examples "a Performance Assessment Strategy" do
    let(:strategy) { described_class.new }

    # Do we reaaly need this? Lets first implement the new strategy format
    xit "maintains a reference for the Cloud Capacitor passed in" do
      strategy.capacitor.should_not be_nil
    end

    it "accepts a reference to a Capacitor" do
      expect(strategy).to respond_to(:capacitor=).with(1).argument
    end

    it "can select lower Configurations from the DeploymentSpace" do
      expect(strategy).to respond_to(:select_lower_configuration_based_on).with(1).argument
    end

    it "can select higher Configurations from the DeploymentSpace" do
      expect(strategy).to respond_to(:select_higher_configuration_based_on).with(1).argument
    end

    it "can select an initial Configuration to start the tests with" do
      expect(strategy).to respond_to :select_initial_configuration
    end

    it "can select an initial workload to start the tests with" do
      expect(strategy).to respond_to(:select_initial_workload).with(1).argument
    end

    it "can raise the current workload" do
      expect(strategy).to respond_to(:raise_workload)
    end
    
    it "can lower the current workload" do
      expect(strategy).to respond_to(:lower_workload)
    end

  end
end