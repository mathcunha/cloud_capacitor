Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
Dir["./lib/cloud_capacitor/**/*.rb"].sort.each {|f| require f}

require "yaml/store"