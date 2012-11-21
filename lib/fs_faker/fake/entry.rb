module FsFaker
  module Fake
    class Entry
      attr_accessor :mode
      attr_accessor :name
      attr_accessor :path

      def initialize(path = nil)
        self.name = FsFaker::OriginalFile.basename(path || '')
        self.path = path
      end
    end
  end
end
