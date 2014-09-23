require 'csv'

module CloudCapacitor
  module Executors
    
    class DummyExecutor
      include Log

      def initialize
        # nested hash initialization
        # Thanks to Anand Immannavar
        # http://anandimmannavar.wordpress.com/2013/05/06/ruby-nested-hash-initialization/
        @result_for = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc) }

        path = File.expand_path('../../../..', __FILE__)
        file = File.join( path, "wordpress_cpu_mem.csv" )

        CSV.foreach(file, headers: true) do |row|
          @result_for[row["workload"].to_i][row["instances"].to_i][row["provider_id"]] =
            { value: row["percentile"].to_f, 
              cpu:   row["cpubusy.my_quantile"].to_f, 
              mem:   row["%_mem.my_quantile"].to_f }
        end

      end

      def run(configuration:, workload:)
        # log.debug "DummyExecutor: executing performance test..."
        res = @result_for[workload][configuration.size][configuration.name]
        result = Result.new(value: res[:value], cpu: res[:cpu], mem: res[:mem])
        # log.debug "DummyExecutor: response time = #{result.raw_value}ms Workload: #{workload} Configuration: #{configuration.size}.#{configuration.name}\n"
        result
      end
    end

  end
end
