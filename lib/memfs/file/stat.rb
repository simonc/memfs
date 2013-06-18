require 'forwardable'

module MemFs
  class File
    class Stat
      extend Forwardable

      attr_reader :entry

      def initialize(path, dereference = false)
        entry = fs.find!(path)
        @entry = dereference ? entry.dereferenced : entry
      end

      def directory?
        File.directory? entry.path
      end

      def symlink?
        File.symlink? entry.path
      end

      def mode
        entry.mode
      end

      def atime
        entry.atime
      end

      def mtime
        entry.mtime
      end

      def uid
        entry.uid
      end

      def gid
        entry.gid
      end

      def blksize
        4096
      end

      def file?
        entry.is_a?(Fake::File)
      end

      def world_writable?
        entry.mode if (entry.mode & Fake::Entry::OWRITE).nonzero?
      end

      def sticky?
        !!(entry.mode & Fake::Entry::USTICK).nonzero?
      end

      def dev
        entry.dev
      end

      def ino
        entry.ino
      end

      private

      def fs
        FileSystem.instance
      end
    end
  end
end
