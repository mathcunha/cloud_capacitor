module CloudCapacitor
  module Executors
    
    class Dummy_Executor
      def run(configuration:, workload:)
        {response_time: 500, cpu: 45.5, mem: 38.9, errors: 0, requests: 1000}
      end
    end

  end
end
