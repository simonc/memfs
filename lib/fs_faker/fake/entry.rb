module FsFaker
  module Fake
    class Entry
      attr_accessor :atime
      attr_accessor :gid
      attr_accessor :mtime
      attr_accessor :name
      attr_accessor :parent
      attr_accessor :uid
      attr_reader :mode

      def initialize(path = nil)
        time = Time.now
        self.name = FsFaker::OriginalFile.basename(path || '')
        self.mode = 0666 - FsFaker::File.umask
        self.atime = time
        self.mtime = time
        current_user = Etc.getpwuid
        self.uid = current_user.uid
        self.gid = current_user.gid
      end

      def mode=(mode_int)
        @mode = 0100000 + mode_int
      end

      def last_target
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
        FsFaker::OriginalFile.join(parts)
      end
    end
  end
end
