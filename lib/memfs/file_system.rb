require 'singleton'
require 'memfs/fake/directory'
require 'memfs/fake/file'
require 'memfs/fake/symlink'

module MemFs
  class FileSystem
    include Singleton

    attr_accessor :working_directory
    attr_accessor :registred_entries
    attr_accessor :root

    def basename(path)
      File.basename(path)
    end

    def chdir(path, &block)
      destination = find_directory!(path)

      previous_directory = working_directory
      self.working_directory = destination

      block.call if block
    ensure
      if block
        self.working_directory = previous_directory
      end
    end

    def clear!
      self.root = Fake::Directory.new('/')
      self.mkdir('/tmp')
      self.chdir('/')
    end

    def chmod(mode_int, file_name)
      find!(file_name).mode = mode_int
    end

    def chown(uid, gid, path)
      entry = find!(path).dereferenced
      entry.uid = uid if uid && uid != -1
      entry.gid = gid if gid && gid != -1
    end

    def dirname(path)
      File.dirname(path)
    end

    def entries(path)
      find_directory!(path).entry_names
    end

    def find(path)
      if path == '/'
        root
      elsif dirname(path) == '.'
        working_directory.find(path)
      else
        root.find(path)
      end
    end

    def find!(path)
      find(path) || raise(Errno::ENOENT, path)
    end

    def find_directory!(path)
      entry = find!(path).dereferenced

      raise Errno::ENOTDIR, path unless entry.is_a?(Fake::Directory)

      entry
    end

    def find_parent!(path)
      parent_path = dirname(path)
      find_directory!(parent_path)
    end

    def getwd
      working_directory.path
    end
    alias :pwd :getwd

    def initialize
      clear!
    end

    def link(old_name, new_name)
      file = find!(old_name)

      raise Errno::EEXIST, "(#{old_name}, #{new_name})" if find(new_name)

      link = file.dup
      link.name = basename(new_name)
      find_parent!(new_name).add_entry link
    end

    def mkdir(path)
      raise Errno::EEXIST, path if find(path)
      find_parent!(path).add_entry Fake::Directory.new(path)
    end

    def rename(old_name, new_name)
      file = find!(old_name)
      file.delete

      file.name = basename(new_name)
      find_parent!(new_name).add_entry(file)
    end

    def rmdir(path)
      directory = find!(path)

      raise Errno::ENOTEMPTY, path unless directory.empty?

      directory.delete
    end

    def symlink(old_name, new_name)
      raise Errno::EEXIST, new_name if find(new_name)

      find_parent!(new_name).add_entry Fake::Symlink.new(new_name, old_name)
    end

    def touch(*paths)
      paths.each do |path|
        entry = find(path)

        unless entry
          entry = Fake::File.new(path)
          parent_dir = find_parent!(path)
          parent_dir.add_entry entry
        end

        entry.touch
      end
    end

    def unlink(path)
      entry = find!(path)

      raise Errno::EPERM, path if entry.is_a?(Fake::Directory)

      entry.delete
    end
  end
end
