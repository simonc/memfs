require 'singleton'
require 'fs_faker/fake/directory'
require 'fs_faker/fake/file'

module FsFaker
  class FileSystem
    include Singleton

    attr_accessor :working_directory
    attr_accessor :registred_entries

    def initialize
      self.registred_entries = {}
    end

    def chdir(path, &block)
      previous_directory = working_directory
      self.working_directory = find!(path).path

      if block
        block.call
      end
    ensure
      if block
        self.working_directory = previous_directory
      end
    end

    def getwd
      working_directory
    end
    alias :pwd :getwd

    def find!(path)
      registred_entries[path] || raise(Errno::ENOENT, path)
    end

    def mkdir(path)
      registred_entries[path] = Fake::Directory.new(path)
    end

    def clear!
      self.registred_entries.clear
    end

    def directory?(path)
      registred_entries[path].is_a?(Fake::Directory)
    end

    def touch(path)
      registred_entries[path] = Fake::File.new(path)
    end

    def chmod(mode_int, file_name)
      find!(file_name).mode = mode_int
    end
  end
end
