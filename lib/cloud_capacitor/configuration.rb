module CloudCapacitor
  class Configuration
    attr_reader :name, :mem, :price, :cpu
    attr_accessor :size, :vm_type
    
    def initialize(vm_type:, size:)
      @vm_type = vm_type
      @size = size
      @name = @vm_type.name
    end

    def name
      @vm_type.name
    end

    def mem
      @size * @vm_type.mem
    end

    def price
      @size * @vm_type.price
    end

    def cpu
      @size * @vm_type.cpu
    end

    def to_s
      "#{@vm_type.name}(#{@size})[#{cpu} #{mem} #{price}]"
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
      return @size.eql?(object.size) && @vm_type.name.eql?(object.vm_type.name)
    end

  end
end
