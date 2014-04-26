module CloudCapacitor
  module Executors
    
    class DummyExecutor
      include Log

      def run(configuration:, workload:)
        log.debug "DummyExecutor: executing performance test..."
        sleep 0.1
        sla = Settings.capacitor.sla
        fake_response_time = Random.rand (sla * 0.9)..(sla * 1.2)
        log.debug "DummyExecutor: fake response time = #{fake_response_time}ms for a #{sla}ms SLA"
        Result.new(value: fake_response_time,cpu: 75.5, mem: 78.9)
      end
    end

  end
end
