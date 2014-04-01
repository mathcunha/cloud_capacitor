require "spec_helper"
require 'plexus/dot'

module CloudCapacitor
  describe DeploymentSpace do
    
    before(:all) do
      @modes = DeploymentSpace::TRAVERSAL_MODES
      @vm01  = VMType.new(name:"c1",cpu:1, mem:1, price:0.1)
      @vm02  = VMType.new(name:"c2",cpu:2, mem:2, price:0.2)
      @vm03  = VMType.new(name:"c3",cpu:3, mem:3, price:0.3)
      @vm04  = VMType.new(name:"c4",cpu:4, mem:4, price:0.4)
    end

    describe "#new" do      
      subject(:deployment_space) { DeploymentSpace.new }

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

        subject(:deployment_space) { DeploymentSpace.new(file:"configurations.yml") }
        its(:configs) { should have(8).configurations }

        it "raises an error when non existent file passed" do
          expect { DeploymentSpace.new(file:"no_file.yml") }.to raise_error
        end

        it "raises an error when specified file has invalid configurations" do
          expect { DeploymentSpace.new(file:"wrong.yml") }.to raise_error
        end
      end
    end

    context "other methods" do
      subject { DeploymentSpace.new(vm_types: [@vm01, @vm02, @vm03, @vm04]) }

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

      describe "#next_config_by" do
        xit "validates ranking mode correctly" do
          @modes.each do |mode|
            expect { subject.next_config_by(mode) }.to_not raise_error
          end
          expect { subject.next_config_by(:age) }.to raise_error
        end

        xit "does NOT change the current selected configuration" do
          @modes.each do |mode|
            subject.pick("c1")
            expect(subject.next_config_by(mode)).to eql @config02
            expect(subject.current_config).to eql @config01
          end
        end

        context "when past the last Configuration" do
          xit "returns nil " do
            subject.pick("c4")
            @modes.each do |mode|
              expect(subject.next_config_by(mode)).to be_nil
            end
          end
          xit "does NOT change the current selected configuration" do
            subject.pick("c4")
            @modes.each do |mode|
              subject.next_config_by(mode)
              expect(subject.current_config).to eql @config04
            end
          end
        end

        context "when there are remaing Configuration to visit" do
          xit "returns successor Configuration based on specified parameter" do
            @modes.each do |mode|
              subject.pick("c1")
              expect(subject.next_config_by(mode)).to eql @config02
              subject.pick("c3")
              expect(subject.next_config_by(mode)).to eql @config04
            end
          end
        end
      end

      describe "#next_config_by!" do
        xit "changes the current selected configuration correctly" do
          @modes.each do |mode|
            subject.pick("c1")
            subject.next_config_by!(mode)
            subject.current_config.should eql @config02
            subject.pick("c3")
            subject.next_config_by!(mode)
            subject.current_config.should eql @config04
          end
        end

        context "when past the last Configuration" do
          xit "returns nil" do
            subject.pick("c4")
            @modes.each do |mode|
              subject.next_config_by!(mode).should be_nil
            end
          end
          xit "does NOT change the current selected configuration" do
            subject.pick("c4")
            @modes.each do |mode|
              subject.next_config_by!(mode)
              expect(subject.current_config).to eql @config04
            end
          end
        end
      end

      describe "#previous_config_by" do
        xit "validates ranking mode correctly" do
          @modes.each do |mode|
            expect { subject.previous_config_by(mode) }.to_not raise_error
          end
          expect { subject.previous_config_by(:age) }.to raise_error
        end

        xit "does NOT change the current selected configuration" do
          @modes.each do |mode|
            subject.pick("c2")
            expect(subject.previous_config_by(mode)).to eql @config01
            expect(subject.current_config).to eql @config02
          end
        end


        context "when past the first Configuration" do
          xit "returns nil" do
            subject.pick("c1")
            @modes.each do |mode|
              expect(subject.previous_config_by(mode)).to be_nil
            end
          end
          xit "does NOT change the current selected configuration" do
            subject.pick("c1")
            @modes.each do |mode|
              subject.previous_config_by(mode)
              expect(subject.current_config).to eql @config01
            end
          end
        end

        context "when there are remaing Configuration to visit" do
          xit "returns predecessor Configuration based on specified parameter" do
            @modes.each do |mode|
              subject.pick("c2")
              expect(subject.previous_config_by(mode)).to eql @config01
              subject.pick("c4")
              expect(subject.previous_config_by(mode)).to eql @config03
            end
          end
        end
      end

      describe "#previous_config_by!" do
        xit "changes the current selected configuration correctly" do
          @modes.each do |mode|
            subject.pick("c2")
            subject.previous_config_by!(mode)
            expect(subject.current_config).to eql @config01
            subject.pick("c4")
            subject.previous_config_by!(mode)
            expect(subject.current_config).to eql @config03
          end
        end

        context "when past the first Configuration" do
          xit "returns nil" do
            subject.pick("c1")
            @modes.each do |mode|
              expect(subject.previous_config_by!(mode)).to be_nil
            end
          end
          xit "does NOT change the current selected configuration" do
            subject.pick("c1")
            @modes.each do |mode|
              subject.previous_config_by(mode)
              expect(subject.current_config).to eql @config01
            end
          end
        end
      end
    end
  end
end