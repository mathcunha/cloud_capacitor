require "spec_helper"

module CloudCapacitor
  describe Capacitor do
    before :all do
      @cloud_capacitor = Capacitor.new
      @config01 = Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
      @config02 = Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)
      @config03 = Configuration.new(name:"c3",cpu:3, mem:3, price:0.3)
      @config04 = Configuration.new(name:"c4",cpu:4, mem:4, price:0.4)
    end

    describe "#new" do
      it "loads default list of Configurations" do
        @cloud_capacitor.deployment_space.should have_at_least(1).configuration
      end

      it "sets current configurations by default" do
        @cloud_capacitor.current_config.should be_an_instance_of Configuration
        @cloud_capacitor.current_config.should equal @cloud_capacitor.deployment_space[0]
      end

      context "with no parameters" do
        it "accepts zero arguments" do
          @cloud_capacitor.should be_an_instance_of Capacitor
        end

        it "sets default values for sla and delta" do
          @cloud_capacitor.sla.should_not be nil
          @cloud_capacitor.delta.should_not be nil
        end

        xit "sets a default Executor" do
          @cloud_capacitor.executor.should_not be nil
        end
      end

      context "with sla parameter" do
        capacitor = Capacitor.new(sla:1000)

        it "accepts sla argument" do
          capacitor.should be_an_instance_of Capacitor
        end

        it "sets specified value for sla and default for delta" do
          capacitor.sla.should eql 1000
          capacitor.delta.should_not be nil
        end
      end

      context "with delta parameter" do
        capacitor = Capacitor.new(delta:0.5)

        it "accepts delta argument" do
          capacitor.should be_an_instance_of Capacitor
        end

        it "sets specified value for delta and default for sla" do
          capacitor.sla.should_not be nil
          capacitor.delta.should eql 0.5
        end
      end

      context "with both sla and delta parameters" do
        capacitor = Capacitor.new(sla:1500, delta:0.3)

        it "accepts sla argument" do
          capacitor.should be_an_instance_of Capacitor
        end

        it "sets specified value for sla and default for delta" do
          capacitor.sla.should eql 1500
          capacitor.delta.should eql 0.3
        end
      end

      context "with specified deploymnt space file parameter" do
        File.open "configurations.yml", "w" do |f|
          f.write [Configuration.new(name:"c1",cpu:1, mem:1, price:0.1),
                   Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)]
                  .to_yaml
        end
        File.open "wrong.yml", "w" do |f|
          f.write YAML::dump ["not a configuration 01", "not a configuration 02"]
        end

        capacitor = Capacitor.new(file:"configurations.yml")

        it "loads list of Configurations" do
          capacitor.deployment_space.should have(2).configurations
        end

        it "raises an error when invalid file passed" do
          expect { Capacitor.new(file:"no_file.yml") }.to raise_error
        end

        it "raises an error when specified file has invalid configurations" do
          expect { Capacitor.new(file:"wrong.yml") }.to raise_error
        end
      end
    end

    it "allows querying for the associated Executor at runtime" do
      @cloud_capacitor.should respond_to :executor
    end

    it "allows changing the associated Executor at runtime" do
      @cloud_capacitor.should respond_to :executor=
    end

    it "allows querying for the associated Strategy at runtime" do
      @cloud_capacitor.should respond_to :strategy
    end

    it "allows changing the associated Strategy at runtime" do
      @cloud_capacitor.should respond_to :strategy=
    end

    describe "#run_for" do 
      xit "execute tests for a list of workloads" do
        @cloud_capacitor.should respond_to(:run_for).with(1).argument
      end

      xit "validates that an Executor is already associated" do
        cap = Capacitor,new
        cap.strategy = double()
        cap.executor.should be_nil
        cap.strategy.should_not be_nil

        expect { cap.run_for(100) }.to raise_error(Err::NoExecutorConfiguredError)

        cap.executor = double()
        cap.executor.should_not be_nil

        expect { cap.run_for(100) }.to_not raise_error(Err::NoExecutorConfiguredError)
      end

      xit "validates that a Strategy is already associated" do
        cap = Capacitor,new
        cap.executor = double()
        cap.strategy.should be_nil
        cap.executor.should_not be_nil

        expect { cap.run_for(100) }.to raise_error(Err::NoStrategyConfiguredError)

        cap.strategy = double()
        cap.strategy.should_not be_nil

        expect { cap.run_for(100) }.to_not raise_error(Err::NoStrategyConfiguredError)
      end

    end

    describe "#execute" do
      it "runs a performance test against a specified configuration and for a specified workload" do
        @cloud_capacitor.executor.should_receive :run
        @cloud_capacitor.execute configuration: @config01, workload: 100
      end

      it "returns test result information" do
        cfg = Configuration.new(name:"c1.medium",cpu:1, mem:1, price:0.1)
        executor = double("Executor")
        allow(executor).to receive(:run) { {response_time: 2100, cpu: 75.5, mem: 78.9, errors: 0, requests: 1000} }
        @cloud_capacitor.executor = executor

        result = @cloud_capacitor.execute configuration: cfg, workload: 100
        result.should_not be_nil
      end
    end

    describe "#pick" do
      it "selects a valid Configuration from the deployment space" do
        @cloud_capacitor.pick("c3.large")
        @cloud_capacitor.current_config.should be_an_instance_of Configuration
        @cloud_capacitor.current_config.name.should eql "c3.large"
      end

      it "raises an error when invalid Configuration name is specified" do
        expect { @cloud_capacitor.pick("wrong_instance_name") }.to raise_error(Err::InvalidConfigNameError)
      end
    end

    describe "#next_config_by" do
      it "validates ranking mode correctly" do
        @cloud_capacitor.deployment_space = [@config01]
        [:cpu, :mem, :price].each do |mode|
          expect { @cloud_capacitor.next_config_by(mode) }.to_not raise_error
        end
        expect { @cloud_capacitor.next_config_by(:age) }.to raise_error
      end

      it "returns successor Configuration based on specified parameter" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c1")
          @cloud_capacitor.next_config_by(mode).should eql @config02
          @cloud_capacitor.pick("c3")
          @cloud_capacitor.next_config_by(mode).should eql @config04
        end
      end

      it "returns nil when past the last Configuration" do
        @cloud_capacitor.deployment_space = [@config01]
        @cloud_capacitor.pick("c1")
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.next_config_by(mode).should be_nil
        end
      end

      it "does NOT change the current selected configuration" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c1")
          @cloud_capacitor.next_config_by(mode)
          @cloud_capacitor.current_config.should eql @config01
          @cloud_capacitor.pick("c3")
          @cloud_capacitor.next_config_by(mode)
          @cloud_capacitor.current_config.should eql @config03
        end
      end
    end

    describe "#next_config_by!" do
      it "changes the current selected configuration correctly" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c1")
          @cloud_capacitor.next_config_by!(mode)
          @cloud_capacitor.current_config.should eql @config02
          @cloud_capacitor.pick("c3")
          @cloud_capacitor.next_config_by!(mode)
          @cloud_capacitor.current_config.should eql @config04
        end
      end
      it "returns nil when past the last Configuration" do
        @cloud_capacitor.deployment_space = [@config01]
        @cloud_capacitor.pick("c1")
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.next_config_by!(mode).should be_nil
          @cloud_capacitor.current_config.should eql @config01
        end
      end
    end

    describe "#previous_config_by" do
      it "validates ranking mode correctly" do
        @cloud_capacitor.deployment_space = [@config01]
        [:cpu, :mem, :price].each do |mode|
          expect { @cloud_capacitor.previous_config_by(mode) }.to_not raise_error
        end
        expect { @cloud_capacitor.previous_config_by(:age) }.to raise_error
      end

      it "returns predecessor Configuration based on specified parameter" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c2")
          @cloud_capacitor.previous_config_by(mode).should eql @config01
          @cloud_capacitor.pick("c4")
          @cloud_capacitor.previous_config_by(mode).should eql @config03
        end
      end

      it "returns nil when past the first Configuration" do
        @cloud_capacitor.deployment_space = [@config02]
        @cloud_capacitor.pick("c2")
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.previous_config_by(mode).should be_nil
        end
      end

      it "does NOT change the current selected configuration" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c2")
          @cloud_capacitor.previous_config_by(mode)
          @cloud_capacitor.current_config.should eql @config02
          @cloud_capacitor.pick("c4")
          @cloud_capacitor.previous_config_by(mode)
          @cloud_capacitor.current_config.should eql @config04
        end
      end

    end

    describe "#previous_config_by!" do
      it "changes the current selected configuration correctly" do
        @cloud_capacitor.deployment_space = [@config01, @config02, @config03, @config04]
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.pick("c2")
          @cloud_capacitor.previous_config_by!(mode)
          @cloud_capacitor.current_config.should eql @config01
          @cloud_capacitor.pick("c4")
          @cloud_capacitor.previous_config_by!(mode)
          @cloud_capacitor.current_config.should eql @config03
        end
      end

      it "returns nil when past the first Configuration" do
        @cloud_capacitor.deployment_space = [@config02]
        @cloud_capacitor.pick("c2")
        [:cpu, :mem, :price].each do |mode|
          @cloud_capacitor.previous_config_by!(mode).should be_nil
          @cloud_capacitor.current_config.should eql @config02
        end
      end
    end

  end
end