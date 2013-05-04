require 'fs_faker/fake/entry'
require 'fs_faker/fake/file/content'

module FsFaker
  module Fake
    class File < Entry
      attr_accessor :content

      # TODO: delegate everything to @content
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
