require 'memfs/filesystem_access'

module MemFs
  class Dir
    extend FilesystemAccess

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

    def self.mkdir(path)
      fs.mkdir path
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
    end

    private

    attr_accessor :entry
  end
end
