require 'coveralls'
require 'memfs'

Coveralls.wear!

RSpec.configure do |config|
  config.before :each do
    MemFs::File.umask(0022)
    MemFs::FileSystem.instance.clear!
  end
end

def fs
  MemFs::FileSystem.instance
end
