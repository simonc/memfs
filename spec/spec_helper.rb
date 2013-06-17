require 'memfs'

RSpec.configure do |config|
  config.before :each do
    MemFs::File.reset!
    MemFs::FileSystem.instance.clear!
  end
end
