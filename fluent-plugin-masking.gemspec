lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require ('./lib/fluent/plugin/version.rb')

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-masking"
  spec.version       = FilterMasking::VERSION

  spec.authors       = ["Shai Moria", "Niv Lipetz"]
  spec.email         = ["shai.moria@zooz.com", "niv.lipetz@zooz.com"]
  spec.description   = "Fluentd Filter plugin to mask given fields in messages"
  spec.summary       = "Fluentd Filter plugin to mask given fields in messages"
  spec.homepage      = "https://github.com/zooz"

  spec.files         = `git ls-files`.split($\)
  spec.require_paths = ["lib"]
  spec.license = "Apache-2.0"

  spec.required_ruby_version = '>= 2.1'
  
  spec.add_runtime_dependency "fluentd", ">= 0.14.0", "< 2"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", ">= 3.1.0"
  spec.add_development_dependency "test-unit-rr"
end
