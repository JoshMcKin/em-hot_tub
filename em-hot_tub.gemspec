# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'em/hot_tub/version'

Gem::Specification.new do |spec|
  spec.name          = "em-hot_tub"
  spec.version       = EventMachine::HotTub::VERSION
  spec.authors       = ["Joshua Mckinney"]
  spec.email         = ["joshmckin@gmail.com"]
  spec.summary       = %q{EventMachine version of HotTub.}
  spec.description   = %q{EventMachine version of HotTub.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "hot_tub", "~> 1.0.0"
  spec.add_runtime_dependency "em-synchrony"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-autotest"
  spec.add_development_dependency "autotest"
  spec.add_development_dependency "em-http-request"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "puma", "~> 2.0.0"

end
