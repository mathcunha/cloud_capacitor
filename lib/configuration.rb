module CloudCapacitor
  class Configuration
    attr_accessor :name, :cpu, :mem, :price
    def initialize(name:, cpu:, mem:, price:)
      @name = name
      @cpu = cpu
      @mem = mem
      @price = price
    end

    def ecu
      cpu
    end

    def ecu=(cpu)
      @cpu = cpu
    end
  end
end