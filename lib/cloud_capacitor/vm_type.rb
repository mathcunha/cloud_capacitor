module CloudCapacitor
  class VMType
    attr_accessor :name, :cpu, :mem, :price

    def initialize(name:, cpu:, mem:, price:)
      @name = name
      @cpu = cpu
      @mem = mem
      @price = price
    end
    
  end
end