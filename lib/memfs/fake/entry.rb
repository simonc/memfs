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

      attr_accessor :atime
      attr_accessor :gid
      attr_accessor :mtime
      attr_accessor :name
      attr_accessor :parent
      attr_accessor :uid
      attr_reader :mode

      def initialize(path = nil)
        time = Time.now
        self.name = MemFs::File.basename(path || '')
        self.mode = 0666 - MemFs::File.umask
        self.atime = time
        self.mtime = time
        current_user = Etc.getpwuid
        self.uid = current_user.uid
        self.gid = current_user.gid
      end

      def mode=(mode_int)
        @mode = 0100000 | mode_int
      end

      def dereferenced
        self
      end

      def touch
        self.atime = self.mtime = Time.now
      end

      def find(path)
        raise Errno::ENOTDIR, self.path
      end

      def delete
        parent.remove_entry self
      end

      def path
        parts = [parent && parent.path, name].compact
        MemFs::File.join(parts)
      end

      def dev
        @dev ||= rand(1000)
      end

      def ino
        @ino ||= rand(1000)
      end
    end
  end
end
