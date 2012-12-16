require 'singleton'
require 'fs_faker/fake/directory'
require 'fs_faker/fake/file'
require 'fs_faker/fake/symlink'

module FsFaker
  class FileSystem
    include Singleton

    attr_accessor :working_directory
    attr_accessor :registred_entries

    def initialize
      self.registred_entries = {}
    end

    def chdir(path, &block)
      destination = find!(path).last_target

      unless destination.is_a?(Fake::Directory)
        raise Errno::ENOTDIR, path
      end

      previous_directory = working_directory
      self.working_directory = destination.path

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

    def find(path)
      registred_entries[path]
    end

    def find!(path)
      find(path) || raise(Errno::ENOENT, path)
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

    def touch(*paths)
      paths.each do |path|
        registred_entries[path] ||= Fake::File.new(path)
        registred_entries[path].touch
      end
    end

    def chmod(mode_int, file_name)
      find!(file_name).mode = mode_int
    end

    def symlink(old_name, new_name)
      registred_entries[new_name] = Fake::Symlink.new(new_name, old_name)
    end

    def symlink?(path)
      find(path).is_a?(Fake::Symlink)
    end
  end
end
