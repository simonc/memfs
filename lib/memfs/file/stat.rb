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
        if owned?
          !!(mode & Fake::Entry::UEXEC).nonzero?
        elsif Process.egid == gid
          !!(mode & Fake::Entry::GEXEC).nonzero?
        else
          !!(mode & Fake::Entry::OEXEC).nonzero?
        end
      end

      def executable_real?
        if Process.uid == uid
          !!(mode & Fake::Entry::UEXEC).nonzero?
        elsif Process.gid == gid
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

      def owned?
        uid == Process.euid
      end

      def readable?
        if owned?
          !!(mode & Fake::Entry::UREAD).nonzero?
        elsif Process.egid == gid
          !!(mode & Fake::Entry::GREAD).nonzero?
        else
          !!(mode & Fake::Entry::OREAD).nonzero?
        end
      end

      def readable_real?
        if Process.uid == uid
          !!(mode & Fake::Entry::UREAD).nonzero?
        elsif Process.gid == gid
          !!(mode & Fake::Entry::GREAD).nonzero?
        else
          !!(mode & Fake::Entry::OREAD).nonzero?
        end
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
