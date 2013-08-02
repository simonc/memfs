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
        entry.is_a?(Fake::Directory)
      end

      def executable?
        if owned?
          !!(mode & Fake::Entry::UEXEC).nonzero?
        elsif grpowned?
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
        entry.is_a?(Fake::File)
      end

      def grpowned?
        gid == Process.egid
      end

      def initialize(path, dereference = false)
        entry = fs.find!(path)
        @entry = dereference ? entry.dereferenced : entry
      end

      def owned?
        uid == Process.euid
      end

      def readable?
        user_readable? || group_readable? || !!world_readable?
      end

      def readable_real?
        user_readable_real? || group_readable_real? || !!world_readable?
      end

      def sticky?
        !!(entry.mode & Fake::Entry::USTICK).nonzero?
      end

      def symlink?
        entry.is_a?(Fake::Symlink)
      end

      def world_readable?
        entry.mode - 0100000 if (entry.mode & Fake::Entry::OREAD).nonzero?
      end

      def world_writable?
        entry.mode - 0100000 if (entry.mode & Fake::Entry::OWRITE).nonzero?
      end

      def writable?
        user_writable? || group_writable? || !!world_writable?
      end

      def writable_real?
        user_writable_real? || group_writable_real? || !!world_writable?
      end

      private

      def group_readable?
        grpowned? && !!(mode & Fake::Entry::GREAD).nonzero?
      end

      def group_readable_real?
        Process.gid == gid && !!(mode & Fake::Entry::GREAD).nonzero?
      end

      def group_writable?
        grpowned? && !!(mode & Fake::Entry::GWRITE).nonzero?
      end

      def group_writable_real?
        Process.gid == gid && !!(mode & Fake::Entry::GWRITE).nonzero?
      end

      def user_readable?
        owned? && !!(mode & Fake::Entry::UREAD).nonzero?
      end

      def user_readable_real?
        Process.uid == uid && !!(mode & Fake::Entry::UREAD).nonzero?
      end

      def user_writable?
        owned? && !!(mode & Fake::Entry::UWRITE).nonzero?
      end

      def user_writable_real?
        Process.uid == uid && !!(mode & Fake::Entry::UWRITE).nonzero?
      end
    end
  end
end
