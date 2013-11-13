# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jo_adapter/version'

Gem::Specification.new do |s|
  s.name          = "jo_adapter"
  s.version       = JoAdapter::VERSION
  s.authors       = ["Geeks at Wego"]
  s.email         = ["therealgeeks@wego.com"]
  s.homepage      = "http://www.wego.com"
  s.summary       = "Adapter for the jo gem"
  s.description   = "Adapter for the jo gem"
  s.required_ruby_version = '>= 2.0.0'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_dependency "activesupport"
end
