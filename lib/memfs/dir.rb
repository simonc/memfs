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
    class << self; alias :delete :rmdir; end
  end
end
