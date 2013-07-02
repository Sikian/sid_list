# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sid_list/version'

Gem::Specification.new do |spec|
  spec.name          = "sid_list"
  spec.version       = SidList::VERSION
  spec.authors       = ["Sikian"]
  spec.email         = ["sikian@gmail.com"]
  spec.description   = %q{List containing any type of Object intenteded to be indexed by status and id, making it easy to select all Objects for a given status, update the list, etc.}
  spec.summary       = %q{List indexed by status & id.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
