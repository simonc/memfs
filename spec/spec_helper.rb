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

RSpec::Matchers.define :raise_specific_error do |expected_exception_class|
  match do |block|
    begin
      block.call
    rescue expected_exception_class
      true
    else
      false
    end
  end

  def supports_block_expectations?
    true
  end
end

def _fs
  MemFs::FileSystem.instance
end
