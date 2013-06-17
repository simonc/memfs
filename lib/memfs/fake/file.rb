require 'memfs/fake/entry'
require 'memfs/fake/file/content'

module MemFs
  module Fake
    class File < Entry
      attr_accessor :content

      def initialize(*args)
        super
        @content = Content.new
        @closed = false
      end

      def close
        @closed = true
      end

      def closed?
        @closed
      end
    end
  end
end
