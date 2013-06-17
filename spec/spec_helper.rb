require 'memfs'

RSpec.configure do |config|
  config.before :each do
    MemFs::File.umask(0022)
    MemFs::FileSystem.instance.clear!
  end
end
