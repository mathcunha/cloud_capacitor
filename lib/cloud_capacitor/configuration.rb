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

    # Keep in mind that when one config is NOT < other
    # it does NOT necessarily mean it IS > other
    def < (other)
      return false if other.nil?
      return false if self.equal? other
      return false if self.size > other.size
      
      return true if ( (self.name.eql? other.name) && 
                       (self.size < other.size) )

      return true if ( (self.size == other.size) &&
                       (self.cpu < other.cpu)    &&
                       (self.mem < other.mem) )

      return false
    end
    
    # Keep in mind that when one config is NOT > other
    # it does NOT necessarily mean it IS < other
    def > (other)
      return false if other.nil?
      return false if self.equal? other
      return false if self.size < other.size
      
      return true if ( (self.name.eql? other.name) &&
                       (self.size > other.size) )

      return true if ( (self.size == other.size) &&
                       (self.cpu > other.cpu)    &&
                       (self.mem > other.mem) )

      return false
    end

    def <= (other)
      return false if other.nil?
      return true  if self.equal? other
      return true  if self < other
      return true  if self == other
    end

    def >= (other)
      return false if other.nil?
      return true  if self.equal? other
      return true  if self > other
      return true  if self == other
    end

    def == (other)
      return false if other.nil?
      return true  if self.equal? other
      return true  if ( (self.size == other.size) &&
                        (self.cpu  == other.cpu)  &&
                        (self.mem  == other.mem) )
      return false
    end

    def <=> (other)
      return -1 if (self  < other)
      return  0 if (self == other)
      return  1 if (self  > other)
      raise Err::UncomparableConfigurationError
    end

    def eql? (other)
      return self == other
    end
  end
end
