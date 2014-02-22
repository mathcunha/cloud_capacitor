module CloudCapacitor
  module Strategies
    
    class NM_Strategy
      attr_accessor :capacitor
      
      def initialize(capacitor:)
        @capacitor = capacitor
      end

      def evaluate_performance_results(workload:)
        @capacitor.execute(configuration: @capacitor.current_config, workload: workload)

        @capacitor.current_config
      end

    end

  end
end