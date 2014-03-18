module CloudCapacitor
  class Result
    attr_accessor :raw_value, :raw_cpu, :raw_mem, :normalized
  
    def initialize(value:, cpu:, mem:, normalized: false, sla: nil, delta: nil)
      @raw_value = value
      @raw_cpu = cpu
      @raw_mem = mem

      @normalized = false

      @sla   = sla if sla
      @delta = delta if delta
      @normalized = true if normalized && sla && delta
    end
    
    def cpu
      return raw_cpu unless normalized?
      return :high  if raw_cpu > Settings.capacitor.cpu_limit
      return :low_moderate
    end

    def mem
      return raw_mem unless normalized?
      return :high  if raw_mem > Settings.capacitor.mem_limit
      return :low_moderate
    end

    def met?(sla)
      @raw_value <= sla
    end

    def value

      return raw_value unless normalized?
      diff = (raw_value.to_f - @sla.to_f) / @sla
      if diff < 0
        direction = :down
      else
        direction = :up
      end

      return {deviation: :small,  direction: direction}  if diff.abs <= (@delta / 2)
      return {deviation: :medium, direction: direction}  if diff.abs <= @delta
      return {deviation: :large,  direction: direction}
    end
  
    def normalized?
      @normalized
    end

    # def normalized(sla:, delta:)
    #   normalized_result = Result.new(value:raw_value, cpu:raw_cpu, mem:raw_mem, normalized: true, sla: sla, delta: delta)
    # end

    def normalize!(sla:, delta:)
      @normalized = true
      @sla = sla
      @delta = delta
      return self
    end

    def denormalize!(sla:, delta:)
      @normalized = false
      @sla = nil
      @delta = nil
      return self
    end
  end
end