require "spec_helper"

module CloudCapacitor
  describe Capacitor do
    before :all do
      @config01 = Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
      @config02 = Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)
      @config03 = Configuration.new(name:"c3",cpu:3, mem:3, price:0.3)
      @config04 = Configuration.new(name:"c4",cpu:4, mem:4, price:0.4)
    end

    subject(:cloud_capacitor) { Capacitor.new }

    describe "#new" do

      its(:deployment_space) { should_not be_nil }

      context "with no parameters" do
        it "accepts zero arguments" do
          expect(subject).to be_an_instance_of Capacitor
        end

        its(:sla)   {should_not be nil}
        its(:delta) {should_not be nil}

      end

      context "with sla parameter" do
        subject(:capacitor) { Capacitor.new(sla:1000) }

        it "accepts sla argument" do
          expect(subject).to be_an_instance_of Capacitor
        end

        its(:sla)   {should eql 1000}
        its(:delta) {should_not be nil}
      end

      context "with delta parameter" do
        subject(:capacitor) { Capacitor.new(delta:0.5) }

        it "accepts delta argument" do
          expect(subject).to be_an_instance_of Capacitor
        end

        its(:sla)   {should_not be nil}
        its(:delta) {should eql 0.5}
      end

      context "with both sla and delta parameters" do
        subject(:capacitor) { Capacitor.new(sla:1500, delta:0.3) }

        it "accepts sla argument" do
          expect(subject).to be_an_instance_of Capacitor
        end

        its(:sla)   {should eql 1500}
        its(:delta) {should eql 0.3}
      end
    end

    it "allows querying for the associated Executor at runtime" do
      expect(subject).to respond_to :executor
    end

    it "allows changing the associated Executor at runtime" do
      expect(subject).to respond_to :executor=
    end

    it "allows querying for the associated Strategy at runtime" do
      expect(subject).to respond_to :strategy
    end

    it "allows changing the associated Strategy at runtime" do
      expect(subject).to respond_to :strategy=
    end

    it "allows querying for the current workload being tested" do
      expect(subject).to respond_to :current_workload
    end
    
    it "allows querying for the unexplored configurations for the current workload being tested" do
      expect(subject).to respond_to :unexplored_configurations
    end

    it "allows querying for the unexplored workloads for the current Configuration being tested" do
      expect(subject).to respond_to :unexplored_workloads
    end
    
    it "execute tests for a list of workloads" do
      expect(subject).to respond_to(:run_for).with(1).argument
    end

    describe "#unexplored_workloads" do
      xit "lists all workloads for which the current Configuration has not been tested yet" do
      end
    end

    describe "#unexplored_configurations" do
      xit "lists all Configurations that have not been tested for the current workload" do
      end
    end

    describe "#run_for" do 

      it "requires an Executor to be associated" do
        strategy = double("Strategy")
        allow(strategy).to receive(:capacitor=)
        allow(strategy).to receive(:select_higher_configuration_based_on)

        subject.strategy = strategy
        subject.executor = nil
        expect { subject.run_for(100) }.to raise_error(Err::NoExecutorConfiguredError)
      end

      context "when an Executor is associated" do
        it "runs the test with no complains" do
          strategy = double("Strategy")
          allow(strategy).to receive(:capacitor=)
          allow(strategy).to receive(:select_higher_configuration_based_on)

          subject.strategy = strategy
          subject.executor = Executors::DummyExecutor.new
          expect { subject.run_for(100) }.to_not raise_error
        end
      end

      it "requires a Strategy to be associated" do
        executor = double("Executor")

        subject.executor = executor
        expect { subject.run_for(100) }.to raise_error(Err::NoStrategyConfiguredError)
      end

      context "when a Strategy is associated" do
        it "runs the test with no complains" do
          executor = double("Executor")
          allow(executor).to receive(:run) { Result.new(value: 2100, cpu: 75.5, mem: 78.9) }

          strategy = double("Strategy")
          allow(strategy).to receive(:capacitor=)
          allow(strategy).to receive(:select_higher_configuration_based_on)

          subject.executor = executor
          subject.strategy = strategy
          expect { subject.run_for(100) }.to_not raise_error
        end
      end

      it "validates that workloads are positive integer numbers only" do
        executor = double("Executor")
        strategy = Strategies::NM_Strategy.new

        subject.executor = executor
        subject.strategy = strategy

        expect { subject.run_for(100, "200") }.to raise_error
        expect { subject.run_for(100, 200.0) }.to raise_error

      end

      it "runs a performance test for a list of workloads" do
        executor = double("Executor")
        strategy = double("Strategy")
        allow(executor).to receive(:run) { Result.new(value: 2100, cpu: 75.5, mem: 78.9) }
        allow(strategy).to receive(:capacitor=)
        allow(strategy).to receive(:select_higher_configuration_based_on)
        subject.executor = executor
        subject.strategy = strategy
        expect(subject.executor).to receive(:run).twice
        expect(subject.run_for(100,200)).to_not be_nil
      end

      xit "returns a hash mapping a workload to its candidate Configurations" do
      end
      
    end
  end
end