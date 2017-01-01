module MemFs
  module Fake
    class Entry
      UREAD  = 00100
      UWRITE = 00200
      UEXEC  = 00400
      GREAD  = 00010
      GWRITE = 00020
      GEXEC  = 00040
      OREAD  = 00001
      OWRITE = 00002
      OEXEC  = 00004
      RSTICK = 01000
      USTICK = 05000
      SETUID = 04000
      SETGID = 02000

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
        %i[atime birthtime ctime mtime].each do |time_attr|
          self.send("#{time_attr}=", time)
        end
        self.gid = Process.egid
        self.mode = 0666 - MemFs::File.umask
        self.name = MemFs::File.basename(path || '')
        self.uid = Process.euid
      end

      def ino
        @ino ||= rand(1000)
      end

      def mode=(mode_int)
        @mode = 0100000 | mode_int
      end

      def path
        parts = [parent && parent.path, name].compact
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
