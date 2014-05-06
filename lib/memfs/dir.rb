require 'memfs/filesystem_access'

module MemFs
  class Dir
    extend FilesystemAccess
    include Enumerable

    attr_accessor :pos

    def self.chdir(path, &block)
      fs.chdir path, &block
      return 0
    end

    def self.entries(dirname, opts = {})
      fs.entries(dirname)
    end

    def self.exists?(path)
      File.directory?(path)
    end
    class << self; alias :exist? :exists?; end

    def self.foreach(dirname, &block)
      return to_enum(__callee__, dirname) unless block

      entries(dirname).each(&block)
    end

    def self.getwd
      fs.getwd
    end
    class << self; alias :pwd :getwd; end

    def self.home(*args)
      original_dir_class.home(*args)
    end

    def self.mkdir(path)
      fs.mkdir path
    end

    def self.open(dirname)
      dir = new(dirname)

      if block_given?
        yield dir
      else
        dir
      end
    ensure
      dir && dir.close if block_given?
    end

    def self.rmdir(path)
      fs.rmdir path
    end

    class << self
      alias :delete :rmdir
      alias :unlink :rmdir
    end

    def initialize(path)
      self.entry = fs.find_directory!(path)
      self.state = :open
      self.pos = 0
    end

    def close
      if state == :closed
        fail IOError, 'closed directory'
      end
      self.state = :closed
    end

    def each(&block)
      return to_enum(__callee__) unless block
      entry.entry_names.each(&block)
    end

    def path
      entry.path
    end
    alias :to_path :path

    def read
      name = entries[pos]
      self.pos += 1
      name
    end

    private

    attr_accessor :entry, :state

    def self.original_dir_class
      MemFs::OriginalDir
    end
  end
end
