module CloudCapacitor
  module Executors
    
    class DummyExecutor
      include Log

      def run(configuration:, workload:)
        log.debug "DummyExecutor: returning result"
        Result.new(value: 2100, cpu: 75.5, mem: 78.9)
      end
    end

  end
end
