# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memfs/version'

Gem::Specification.new do |gem|
  gem.name          = "memfs"
  gem.version       = MemFs::VERSION
  gem.authors       = ["Simon COURTOIS"]
  gem.email         = ["scourtois@cubyx.fr"]
  gem.description   = "MemFs provides a fake file system that can be used " \
                      "for tests. Strongly inspired by FakeFS."
  gem.summary       = "memfs-#{MemFs::VERSION}"
  gem.homepage      = "http://github.com/simonc/memfs"

  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "coveralls", "~> 0.6"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 2.12"
  gem.add_development_dependency "guard", "~> 1.5"
  gem.add_development_dependency "guard-rspec", "~> 2.1"
  gem.add_development_dependency "rb-inotify", "~> 0.8"
  gem.add_development_dependency "rb-fsevent", "~> 0.9"
  gem.add_development_dependency "rb-fchange", "~> 0.0"
end
