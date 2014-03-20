module CloudCapacitor
  class ConfigurationGroup
    attr_reader :size, :configuration
    def initialize(configuration:, size:)
      @configuration = configuration
      @size = size
      @name = @configuration.name
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
      "#{@configuration.name}(#{@size})[#{cpu} #{mem} #{price}]"
    end

    def hash
      "#{@size.to_s}#{@name}".hash
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
