# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_capacitor/version'

Gem::Specification.new do |spec|
  spec.name          = "cloud_capacitor"
  spec.version       = CloudCapacitor::VERSION
  spec.authors       = ["Marcelo Goncalves"]
  spec.email         = ["marcelocg@gmail.com"]
  spec.summary       = %q{Capacity planning heuristics for the cloud}
  spec.description   = %q{Cloud Capacitor implements some heuristics to help you find 
                          the best machine configuration that suites your needs in terms
                          of price and/or performance}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_dependency "settingslogic"
  spec.add_dependency "google_drive"

end
