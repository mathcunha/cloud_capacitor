module CloudCapacitor
  module Strategies
    
    class NM_Strategy
      attr_accessor :capacitor
      
      def initialize(capacitor:)
        @capacitor = capacitor
      end

      def best_configuration_for(workload:)
        eval_performance(workload)
        @capacitor.current_config
      end

      protected
        def eval_performance(workload)
          capacitor.execute(configuration: @capacitor.current_config, workload: workload)
        end

    end

  end
end