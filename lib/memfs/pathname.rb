require 'memfs/filesystem_access'

module MemFs
  class Pathname
    extend FilesystemAccess

    def initialize(path)
      @path = '' + path
    end

    def to_s
      path
    end
    alias_method :to_str, :to_s

    private

    attr_reader :path
  end
end
