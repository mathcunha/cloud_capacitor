require "spec_helper"
require 'plexus/dot'

module CloudCapacitor
  describe DeploymentSpace do
    
    before :all do
      @vm01   = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
      @vm02   = VMType.new(name:"c2",cpu:2, mem:2, price:0.2)
      @conf01_01 = Configuration.new(vm_type: @vm01, size: 1)
      @conf01_02 = Configuration.new(vm_type: @vm01, size: 2)
      @conf02_01 = Configuration.new(vm_type: @vm02, size: 1)
      @conf02_02 = Configuration.new(vm_type: @vm02, size: 2)
    end
    
    subject(:deployment_space) { DeploymentSpace.new vm_types: [@vm01, @vm02] }

    describe "#new" do      

      it "sets a current configuration by default" do
        expect(deployment_space.current_config).to be_an_instance_of Configuration
        expect(deployment_space.current_config).to equal deployment_space.configs[0]
      end

      context "with no parameters" do
        it "accepts zero arguments" do
          expect(deployment_space).to be_an_instance_of DeploymentSpace
        end
        it "loads default list of Configurations" do
          expect(deployment_space.configs).to have_at_least(1).configuration
        end
      end

      context "with specified VM Types list parameter" do
        subject(:deployment_space) { DeploymentSpace.new(vm_types: [@vm01, @vm02]) }
        its(:vm_types) { should have(2).vm_types }
        its(:vm_types) { should eql [@vm01, @vm02] }
      end

      context "with specified deployment space file parameter" do
        before do
          File.open "configurations.yml", "w" do |f|
            f.write [@vm01, @vm02].to_yaml
          end
          File.open "wrong.yml", "w" do |f|
            f.write YAML::dump ["not a configuration 01", "not a configuration 02"]
          end
        end 
        
        it "raises an error when non existent file passed" do
          expect { DeploymentSpace.new(file:"no_file.yml") }.to raise_error
        end

        it "raises an error when specified file has invalid configurations" do
          expect { DeploymentSpace.new(file:"wrong.yml") }.to raise_error
        end
      end
    end

    context "other methods" do
      # subject { DeploymentSpace.new(vm_types: [@vm01, @vm02, @vm03, @vm04]) }

      describe "#pick" do
        it "selects a valid Configuration from the DeploymentSpace" do
          subject.pick(1,"c1")
          expect(subject.current_config).to be_an_instance_of Configuration
          expect(subject.current_config.name).to eql "c1"
        end

        it "raises an error when invalid Configuration name is specified" do
          expect { subject.pick(1, "wrong_instance_name") }.to raise_error(Err::InvalidConfigNameError)
        end
      end

      describe "#first" do
        context "with no params" do
          it "returns a Configuration based on :price by default" do
            expect(subject.first).to eql @conf01_01
          end
        end
        context "with mode informed" do
          it "returns a Configuration based on mode" do
            expect(subject.first(:price)).to eql @conf01_01
            expect(subject.first(:mem)).to   eql @conf01_01
            expect(subject.first(:cpu)).to   eql @conf01_01
          end
        end
      end

      describe "#last" do
        context "with no params" do
          it "returns a Configuration based on :price by default" do
            expect(subject.last).to eql @conf02_02
          end
        end
        context "with mode informed" do
          it "returns a Configuration based on mode" do
            expect(subject.last(:price)).to eql @conf02_02
            expect(subject.last(:mem)).to   eql @conf02_02
            expect(subject.last(:cpu)).to   eql @conf02_02
          end
        end
      end

      describe "#select_higher" do
        it "returns an array of Configurations with higher capacity" do
          pending "time to sleep, no brain left for this"
        end
      end

      describe "#select_lower" do
        it "returns an array of Configurations with lower capacity" do
          pending "time to sleep, no brain left for this"
        end
      end
    end
  end
end