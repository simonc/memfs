module MemFs
  module Fake
    class Symlink < Entry
      attr_reader :target

      def initialize(path, target)
        super(path)
        @target = target
      end

      def dereferenced
        fs.find!(target).dereferenced
      end

      def content
        dereferenced.content
      end

      private

      def fs
        @fs ||= FileSystem.instance
      end
    end
  end
end
