# frozen_string_literal: true

module MemFs
  module Fake
    class Entry
      UREAD  = 0o0400
      UWRITE = 0o0200
      UEXEC  = 0o0100
      GREAD  = 0o0040
      GWRITE = 0o0020
      GEXEC  = 0o0010
      OREAD  = 0o0004
      OWRITE = 0o0002
      OEXEC  = 0o0001
      RSTICK = 0o1000
      USTICK = 0o5000
      SETUID = 0o4000
      SETGID = 0o2000

      attr_accessor :atime,
        :birthtime,
        :block_device,
        :character_device,
        :ctime,
        :gid,
        :mtime,
        :name,
        :parent,
        :uid
      attr_reader :mode

      def blksize
        4096
      end

      def delete
        parent.remove_entry self
      end

      def dereferenced
        self
      end

      def dereferenced_name
        name
      end

      def dereferenced_path
        path
      end

      def dev
        @dev ||= rand(1000)
      end

      def fileno
        fail NotImplementedError
      end

      def find(_path)
        fail Errno::ENOTDIR, path
      end

      def initialize(path = nil)
        time = Time.now

        self.atime = time
        self.birthtime = time
        self.ctime = time
        self.gid = Process.egid
        self.mode = 0o666 - MemFs::File.umask
        self.mtime = time
        # Preserve full path for root directories (e.g., 'D:/' on Windows)
        # since File.basename('D:/') returns '/' which breaks path matching
        self.name = if path && MemFs.root_path?(path)
                      MemFs.normalize_path(path)
                    else
                      MemFs::File.basename(path || '')
                    end
        self.uid = Process.euid
      end

      def ino
        @ino ||= rand(1000)
      end

      def mode=(mode_int)
        @mode = 0o100000 | mode_int
      end

      def path
        parts = [parent&.path, name].compact
        MemFs::File.join(parts)
      end

      def paths
        [path]
      end

      def touch
        self.atime = self.mtime = Time.now
      end

      def type
        'unknown'
      end
    end
  end
end
