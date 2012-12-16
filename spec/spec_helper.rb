require 'fs_faker'

RSpec.configure do |config|
  config.before :each do
    FsFaker::File.reset!
    FsFaker::FileSystem.instance.clear!
  end
end
