module FsFaker
  module Fake
    class Entry
      attr_accessor :atime
      attr_accessor :mtime
      attr_accessor :name
      attr_accessor :parent
      attr_accessor :path
      attr_reader :mode

      def initialize(path = nil)
        time = Time.now
        self.name = FsFaker::OriginalFile.basename(path || '')
        self.path = path
        self.mode = 0666 - FsFaker::File.umask
        self.atime = time
        self.mtime = time
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
    end
  end
end
