# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fs_faker/version'

Gem::Specification.new do |gem|
  gem.name          = "fs_faker"
  gem.version       = FsFaker::VERSION
  gem.authors       = ["Simon COURTOIS"]
  gem.email         = ["scourtois@cubyx.fr"]
  gem.description   = "FS Faker provides a fake file system that can be used " \
                      "in  test. Strongly inspired by FakeFS"
  gem.summary       = "fs_faker-#{FsFaker::VERSION}"
  gem.homepage      = "http://github.com/simonc/fs_faker"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rspec", "~> 2.12"
end
