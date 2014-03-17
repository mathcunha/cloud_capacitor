module CloudCapacitor
  class ConfigurationGroup
    attr_accessor :configurations
    attr_reader :size, :configuration
    def initialize(configurations:)
      @configuration = configurations[0]
      isValid?(configurations)
      @configurations = configurations
      @size = configurations.size()
    end

    def isValid?(configurations)
	name = @configuration.name
        configurations.each do |configuration|
		raise Err::InvalidConfigurationError, "The configuration must use the same InstanceType. #{name} != #{configuration.name}" if !(name.eql?(configuration.name))
	end
        true
    end

    def ecu
      self.cpu
    end

    def mem
      @size * @configuration.mem
    end

    def price
      @size * @configuration.price
    end

    def cpu
      @size * @configuration.cpu
    end

    def to_s
      @configurations.to_s
    end
  end
end
