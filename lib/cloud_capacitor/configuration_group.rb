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
      @size.to_s + @configuration.name + " " +price.to_s
    end

    def hash
      str = (@size.to_s + @configuration.name)
      (str).hash
    end
    
    def eql?(object)
      if(object.nil?)
        return false
      end
      if(self.equal?(object))
        return true
      end
      return @size.eql?(object.size) && @configuration.name.eql?(object.configuration.name)
    end
  end
end
