lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require ('./lib/fluent/plugin/version.rb')

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-masking"
  spec.version       = FilterMasking::VERSION

  spec.authors       = ["Shai Moria", "Niv Lipetz"]
  spec.email         = ["shai.moria@zooz.com", "niv.lipetz@zooz.com"]
  spec.description   = "Fluentd filter plugin to mask sensitive or privacy records in event messages"
  spec.summary       = "Fluentd filter plugin to mask sensitive or privacy records with `*******` in place of the original value. This data masking plugin protects data such as name, email, phonenumber, address, and any other field you would like to mask."
  spec.homepage      = "https://github.com/PayU/fluent-plugin-masking"

  spec.files         = `git ls-files`.split($\)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.license = "Apache-2.0"

  spec.required_ruby_version = '>= 2.3.8'
  
  spec.add_runtime_dependency "fluentd", ">= 0.14.0"
  spec.add_development_dependency "test-unit", ">= 3.1.0"
  spec.add_development_dependency "test-unit-rr"
end
