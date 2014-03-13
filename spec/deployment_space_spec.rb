require "spec_helper"

module CloudCapacitor
  describe DeploymentSpace do
    
    before(:all) do
      @modes    = DeploymentSpace::TRAVERSAL_MODES
      @config01 = Configuration.new(name:"c1",cpu:1, mem:1, price:0.1)
      @config02 = Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)
      @config03 = Configuration.new(name:"c3",cpu:3, mem:3, price:0.3)
      @config04 = Configuration.new(name:"c4",cpu:4, mem:4, price:0.4)
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

      context "with specified Configuration list parameter" do
        configurations = [Configuration.new(name:"c1",cpu:1, mem:1, price:0.1),
                          Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)]

        subject(:deployment_space) { DeploymentSpace.new(configurations: configurations) }
        its(:configs) { should have(2).configurations }
        its(:configs) { should eql configurations }

      end

      context "with specified deployment space file parameter" do
        File.open "configurations.yml", "w" do |f|
          f.write [Configuration.new(name:"c1",cpu:1, mem:1, price:0.1),
                   Configuration.new(name:"c2",cpu:2, mem:2, price:0.2)]
                  .to_yaml
        end
        File.open "wrong.yml", "w" do |f|
          f.write YAML::dump ["not a configuration 01", "not a configuration 02"]
        end

        subject(:deployment_space) { DeploymentSpace.new(file:"configurations.yml") }
        its(:configs) { should have(2).configurations }

        it "raises an error when non existent file passed" do
          expect { DeploymentSpace.new(file:"no_file.yml") }.to raise_error
        end

        it "raises an error when specified file has invalid configurations" do
          expect { DeploymentSpace.new(file:"wrong.yml") }.to raise_error
        end
      end
    end

    describe "#pick" do
      subject { DeploymentSpace.new(configurations: [@config01, @config02, @config03, @config04]) }
      it "selects a valid Configuration from the DeploymentSpace" do
        subject.pick("c1")
        expect(subject.current_config).to be_an_instance_of Configuration
        expect(subject.current_config.name).to eql "c1"
      end

      it "raises an error when invalid Configuration name is specified" do
        expect { subject.pick("wrong_instance_name") }.to raise_error(Err::InvalidConfigNameError)
      end
    end

    describe "#next_config_by" do
      subject { DeploymentSpace.new(configurations: [@config01, @config02, @config03, @config04]) }

      it "validates ranking mode correctly" do
        @modes.each do |mode|
          expect { subject.next_config_by(mode) }.to_not raise_error
        end
        expect { subject.next_config_by(:age) }.to raise_error
      end

      it "does NOT change the current selected configuration" do
        @modes.each do |mode|
          subject.pick("c1")
          expect(subject.next_config_by(mode)).to eql @config02
          expect(subject.current_config).to eql @config01
        end
      end

      context "when past the last Configuration" do
        it "returns nil " do
          subject.pick("c4")
          @modes.each do |mode|
            expect(subject.next_config_by(mode)).to be_nil
          end
        end
        it "does NOT change the current selected configuration" do
          subject.pick("c4")
          @modes.each do |mode|
            subject.next_config_by(mode)
            expect(subject.current_config).to eql @config04
          end
        end
      end

      context "when there are remaing Configuration to visit" do
        it "returns successor Configuration based on specified parameter" do
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
      subject { DeploymentSpace.new(configurations: [@config01, @config02, @config03, @config04]) }
      it "changes the current selected configuration correctly" do
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
        it "returns nil" do
          subject.pick("c4")
          @modes.each do |mode|
            subject.next_config_by!(mode).should be_nil
          end
        end
        it "does NOT change the current selected configuration" do
          subject.pick("c4")
          @modes.each do |mode|
            subject.next_config_by!(mode)
            expect(subject.current_config).to eql @config04
          end
        end
      end
    end

    describe "#previous_config_by" do
      subject { DeploymentSpace.new(configurations: [@config01, @config02, @config03, @config04]) }

      it "validates ranking mode correctly" do
        @modes.each do |mode|
          expect { subject.previous_config_by(mode) }.to_not raise_error
        end
        expect { subject.previous_config_by(:age) }.to raise_error
      end

      it "does NOT change the current selected configuration" do
        @modes.each do |mode|
          subject.pick("c2")
          expect(subject.previous_config_by(mode)).to eql @config01
          expect(subject.current_config).to eql @config02
        end
      end


      context "when past the first Configuration" do
        it "returns nil" do
          subject.pick("c1")
          @modes.each do |mode|
            expect(subject.previous_config_by(mode)).to be_nil
          end
        end
        it "does NOT change the current selected configuration" do
          subject.pick("c1")
          @modes.each do |mode|
            subject.previous_config_by(mode)
            expect(subject.current_config).to eql @config01
          end
        end
      end

      context "when there are remaing Configuration to visit" do
        it "returns predecessor Configuration based on specified parameter" do
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
      subject { DeploymentSpace.new(configurations: [@config01, @config02, @config03, @config04]) }
      it "changes the current selected configuration correctly" do
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
        it "returns nil" do
          subject.pick("c1")
          @modes.each do |mode|
            expect(subject.previous_config_by!(mode)).to be_nil
          end
        end
        it "does NOT change the current selected configuration" do
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