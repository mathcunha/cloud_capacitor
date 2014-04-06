module CloudCapacitor
  class Result
    attr_accessor :raw_value, :raw_cpu, :raw_mem
    attr_accessor :sla, :low_deviation, :medium_deviation
  
    def initialize(value:, cpu:, mem:)
      @raw_value = value
      @raw_cpu = cpu
      @raw_mem = mem

      @sla              = Settings.capacitor.sla
      @low_deviation    = Settings.capacitor.low_deviation
      @medium_deviation = Settings.capacitor.medium_deviation

    end
    
    def cpu
      return :high  if raw_cpu > Settings.capacitor.cpu_limit
      return :low_moderate
    end

    def mem
      return :high  if raw_mem > Settings.capacitor.mem_limit
      return :low_moderate
    end

    def met_sla?
      @raw_value <= @sla
    end

    def value
      diff = (raw_value.to_f - @sla.to_f) / @sla
      if diff < 0
        direction = :down
      else
        direction = :up
      end

      return {deviation: :low,    direction: direction} if diff.abs <= @low_deviation
      return {deviation: :medium, direction: direction} if diff.abs <= @medium_deviation
      return {deviation: :high,   direction: direction}
    end

  end
end