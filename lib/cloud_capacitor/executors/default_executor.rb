require "redis"
require "json"

module CloudCapacitor
  module Executors
    
    class DefaultExecutor
      def run(configuration:, workload:)
        redis = Redis.new
        res = JSON.parse(redis.brpop("results", 1.0)[1])
        result = Result.new(value: res["value"], cpu: res["cpu"], mem: res["mem"])
        result.errors   = res["errors"]   if res["errors"]
        result.requests = res["requests"] if res["requests"]
        result
      end
    end

  end
end
