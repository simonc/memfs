# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'memfs'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Compares a MemFs class to the original Ruby one ' \
     '(set CLASS to the compared class)'
task :compare do
  class_name = ENV['CLASS'] || 'File'
  klass = Object.const_get(class_name)
  memfs_klass = MemFs.const_get(class_name)

  original_methods = (klass.methods - Object.methods).sort
  original_i_methods = (klass.instance_methods - Object.methods).sort
  implemented_methods = MemFs.activate { (memfs_klass.methods - Object.methods).sort }
  implemented_i_methods = MemFs.activate { (memfs_klass.instance_methods - Object.methods).sort }

  puts "CLASS: #{class_name}"
  puts
  puts 'MISSING CLASS METHODS'
  puts
  puts original_methods - implemented_methods
  puts
  puts 'MISSING INSTANCE METHODS'
  puts
  puts original_i_methods - implemented_i_methods
  puts
  puts 'ADDITIONAL METHODS'
  puts
  puts implemented_methods - original_methods
  puts
  puts 'ADDITIONAL INSTANCE METHODS'
  puts
  puts implemented_i_methods - original_i_methods
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'memfs'
  ARGV.clear
  IRB.start
end
