# frozen_string_literal: true

require 'coveralls'
require 'memfs'

Coveralls.wear!

def _fs
  MemFs::FileSystem.instance
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.color = true
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
  # config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.before { MemFs::FileSystem.instance.clear! }
end

RSpec.shared_examples 'aliased method' do |method, original_method|
  it "##{original_method}" do
    expect(subject.method(method)).to eq(subject.method(original_method))
  end
end
