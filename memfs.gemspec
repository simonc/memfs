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
end
