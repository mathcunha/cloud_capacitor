# These are shared examples[1] to test different Performance Teste Executors
# for the contracted bahavior of receiving a Configuration amd a workload value
# and dispatching the execution of a bunch of tests over the SUT (System Under Test)
# and to respond with the test results. The way the executor manages to execute the
# tests is outside this work's scope. Each implemented Executor should be responsible
# for the task of controlling the test execution.
#
# [1] https://www.relishapp.com/rspec/rspec-core/v/2-14/docs/example-groups/shared-examples
shared_examples "a Performance Test Executor" do
  let(:executor) { described_class.new }

  it "can dispatch the execution of a performance benchmark test" do
    executor.should respond_to(:run).with(2).arguments
  end
  
end