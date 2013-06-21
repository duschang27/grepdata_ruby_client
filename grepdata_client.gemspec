# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grepdata_client/version'

Gem::Specification.new do |spec|
  spec.name          = "grepdata_client"
  spec.version       = GrepdataClient::VERSION
  spec.authors       = ["Dustin Chang"]
  spec.email         = ["dustin@grepdata.com"]
  spec.description   = %q{Ruby client to query Grepdata API}
  spec.summary       = %q{Ruby client to query Grepdata API}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "openssl"
  spec.add_dependency "Date"
  spec.add_dependency "typhoeus",'~> 0.6.3'
  spec.add_dependency "json", '~> 1.8' if RUBY_VERSION < '1.9'
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
