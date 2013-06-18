require 'forwardable'

module MemFs
  class File
    class Stat
      extend Forwardable

      attr_reader :entry

      def_delegators :entry,
                     :atime,
                     :blksize,
                     :dev,
                     :gid,
                     :ino,
                     :mode,
                     :mtime,
                     :uid

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

      def file?
        File.file? entry.path
      end

      def world_writable?
        entry.mode if (entry.mode & Fake::Entry::OWRITE).nonzero?
      end

      def sticky?
        !!(entry.mode & Fake::Entry::USTICK).nonzero?
      end

      private

      def fs
        FileSystem.instance
      end
    end
  end
end
