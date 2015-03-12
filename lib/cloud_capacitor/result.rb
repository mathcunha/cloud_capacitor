module CloudCapacitor
  class Result
    attr_accessor :raw_value, :raw_cpu, :raw_mem, :requests, :errors
    attr_accessor :sla, :low_deviation, :medium_deviation
  
    def initialize(value:, cpu:, mem:, requests:1, errors:0)
      @raw_value = value
      @raw_cpu   = cpu
      @raw_mem   = mem
      @requests  = requests
      @errors    = errors

      @sla              = Settings.capacitor.sla
      @low_deviation    = Settings.capacitor.low_deviation
      @medium_deviation = Settings.capacitor.medium_deviation
    end
    
    def cpu
      return :high  if raw_cpu > Settings.capacitor.cpu_moderate
      return :low if raw_cpu < Settings.capacitor.cpu_low
      return :moderate
    end

    def mem
      return :high  if raw_mem > Settings.capacitor.mem_moderate
      return :low if raw_mem < Settings.capacitor.mem_low
      return :moderate
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
