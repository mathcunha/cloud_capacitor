module CloudCapacitor
  module Executors
    
    class DummyExecutor
      def run(configuration:, workload:)
        Result.new(value: 2100, cpu: 75.5, mem: 78.9)
      end
    end

  end
end
