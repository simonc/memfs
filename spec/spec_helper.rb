# frozen_string_literal: true

require 'simplecov'

SimpleCov.start

require 'memfs'

def _fs
  MemFs::FileSystem.instance
end

# Returns the platform-appropriate root path
def root_path
  MemFs.platform_root
end

# Converts Unix-style path to platform path for expectations
# expected_path('/test-file') => '/test-file' on Unix, 'D:/test-file' on Windows
def expected_path(unix_path)
  MemFs.normalize_path(unix_path)
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
