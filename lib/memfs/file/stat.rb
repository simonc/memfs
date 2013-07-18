require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  class File
    class Stat
      extend Forwardable
      include FilesystemAccess

      attr_reader :entry

      def_delegators :entry,
                     :atime,
                     :blksize,
                     :ctime,
                     :dev,
                     :gid,
                     :ino,
                     :mode,
                     :mtime,
                     :uid

      def directory?
        File.directory? entry.path
      end

      def executable?
        current_user = Etc.getpwuid

        if current_user.uid == uid
          !!(mode & Fake::Entry::UEXEC).nonzero?
        elsif current_user.gid == gid
          !!(mode & Fake::Entry::GEXEC).nonzero?
        else
          !!(mode & Fake::Entry::OEXEC).nonzero?
        end
      end

      def file?
        File.file? entry.path
      end

      def initialize(path, dereference = false)
        entry = fs.find!(path)
        @entry = dereference ? entry.dereferenced : entry
      end

      def sticky?
        !!(entry.mode & Fake::Entry::USTICK).nonzero?
      end

      def symlink?
        File.symlink? entry.path
      end

      def world_writable?
        entry.mode if (entry.mode & Fake::Entry::OWRITE).nonzero?
      end
    end
  end
end
