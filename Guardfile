# frozen_string_literal: true

guard :rspec, cmd: 'bundle exec rspec', all_after_pass: true, all_on_start: true do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }

  watch('lib/memfs/io.rb') { 'spec/memfs/file_spec.rb' }
  watch('spec/spec_helper.rb') { 'spec' }
end
