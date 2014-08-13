module CloudCapacitor
  class VMType
    attr_accessor :name, :cpu, :mem, :price, :category

    def initialize(name:, cpu:, mem:, price:, category:)
      @name = name
      @cpu = cpu
      @mem = mem
      @price = price
      @category = category
    end
    
  end
end
