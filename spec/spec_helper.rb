Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
Dir["./lib/**/*.rb"].sort.each {|f| require f}
require "mock_redis"

# RSpec.configure do |config|
#   config.expect_with :rspec do |c|
#     c.syntax = :expect
#   end
# end