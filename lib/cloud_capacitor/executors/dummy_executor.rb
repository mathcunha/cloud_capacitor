module CloudCapacitor
  module Executors
    
    class DummyExecutor
      def run(configuration:, workload:)
        {response_time: 2100, cpu: 75.5, mem: 78.9, errors: 0, requests: 1000}
      end
    end

  end
end
