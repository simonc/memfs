# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memfs/version'

Gem::Specification.new do |gem|
  gem.name          = 'memfs'
  gem.version       = MemFs::VERSION
  gem.authors       = ['Simon COURTOIS']
  gem.email         = ['scourtois@cubyx.fr']
  gem.description   = 'MemFs provides a fake file system that can be used ' \
                      'for tests. Strongly inspired by FakeFS.'
  gem.summary       = "memfs-#{MemFs::VERSION}"
  gem.homepage      = 'http://github.com/simonc/memfs'

  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.require_paths = ['lib']

  gem.add_development_dependency 'coveralls', '~> 0.6'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'guard', '~> 2.6'
  gem.add_development_dependency 'guard-rspec', '~> 4.3'
  gem.add_development_dependency 'rb-inotify', '~> 0.8'
  gem.add_development_dependency 'rb-fsevent', '~> 0.9'
  gem.add_development_dependency 'rb-fchange', '~> 0.0'
  gem.add_development_dependency 'rubocop', '~> 1.44'

  listen_version = RUBY_VERSION >= '2.2.3' ? '~> 3.1' : '~> 3.0.7'
  gem.add_development_dependency 'listen', listen_version
end
