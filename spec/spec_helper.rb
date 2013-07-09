require 'coveralls'
require 'memfs'

Coveralls.wear!

RSpec.configure do |config|
  config.before :each do
    MemFs::FileSystem.instance.clear!
  end

  shared_examples 'aliased method' do |method, original_method|
    it "##{original_method}" do
      expect(subject.method(method)).to eq(subject.method(original_method))
    end
  end
end

def fs
  MemFs::FileSystem.instance
end
