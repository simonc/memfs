require 'memfs/filesystem_access'

module MemFs
  module Fake
    class Symlink < Entry
      include MemFs::FilesystemAccess

      attr_reader :target

      def initialize(path, target)
        super(path)
        @target = target
      end

      def dereferenced
        fs.find!(target).dereferenced
      end

      def content
        dereferenced.content
      end
    end
  end
end
