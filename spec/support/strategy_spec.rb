# These are shared examples[1] to test different Performance Assessment Strategies
# for the contracted bahavior of using a reference to a Capacitor to execute tests
# over the SUT (System Under Test) and to respond with the best Configuration 
# suitable to run the SUT under the specified workload.
#
# [1] https://www.relishapp.com/rspec/rspec-core/v/2-14/docs/example-groups/shared-examples

shared_examples "a Performance Assessment Strategy" do
  let(:strategy) { described_class.new(CloudCapacitor::CloudCapacitor.new) }

  it "can evaluate performance data for an application" do
    strategy.should respond_to :eval_result
  end

  it "maintains a reference for the Cloud Capacitor passed in" do
    strategy.capacitor.should_not be_nil
  end

  it "executes tests using the Cloud Capacitor facilities" do
    strategy.capacitor.should_receive :execute
    strategy.evaluate_performance_results(workload:100)
  end

  it "responds with the best Configuration suitable to run the SUT under certain workload" do
    strategy.evaluate_performance_results(workload:100).should be_an_instance_of Configuration
  end

end
