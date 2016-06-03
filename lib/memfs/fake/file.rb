require 'memfs/fake/entry'
require 'memfs/fake/file/content'

module MemFs
  module Fake
    class File < Entry
      attr_accessor :content

      def close
        @closed = true
      end

      def closed?
        @closed
      end

      def initialize(*args)
        super
        @content = Content.new
        @closed = false
      end

      def pos
        content.pos
      end

      def pos=(value)
        content.pos = value
      end

      def size
        content.size
      end

      def type
        if block_device then 'blockSpecial'
        elsif character_device then 'characterSpecial'
        else 'file'
        end
      end
    end
  end
end
