module FsFaker
  class Dir
    def self.chdir(path, &block)
      fs.chdir path, &block
      return 0
    end

    def self.getwd
      fs.getwd
    end

    def self.mkdir(path)
      fs.mkdir path
    end

    def self.entries(dirname, opts = {})
      fs.entries(dirname)
    end

    class << self
      alias :pwd :getwd
    end

    private

    def self.fs
      FileSystem.instance
    end
  end
end
