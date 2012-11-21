require 'forwardable'

module FsFaker
  class File
    extend SingleForwardable

    def_delegator :original_file_class, :path

    def self.chmod(mode_int, file_name)
      fs.chmod mode_int, file_name
    end

    def self.directory?(path)
      fs.directory?(path)
    end

    private

    def self.original_file_class
      FsFaker::OriginalFile
    end

    def self.fs
      FileSystem.instance
    end
  end
end
