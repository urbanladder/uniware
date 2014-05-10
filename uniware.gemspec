# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uniware/version'

Gem::Specification.new do |spec|
  spec.name          = "uniware"
  spec.version       = Uniware::VERSION
  spec.authors       = ["Rajat Upadhyaya"]
  spec.email         = ["rajat@urbanladder.com"]
  spec.description   = %q{Ruby interface to the Uniware API}
  spec.summary       = %q{Ruby interface to the Uniware API}
  spec.homepage      = "https://github.com/urbanladder/uniware"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
