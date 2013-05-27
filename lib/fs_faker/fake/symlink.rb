module FsFaker
  module Fake
    class Symlink < Entry
      attr_reader :target

      def initialize(path, target)
        super(path)
        @target = target
      end

      def last_target
        fs.symlink?(target) ? fs.find!(target).last_target : fs.find!(target)
      end

      def content
        last_target.content
      end

      private

      def fs
        @fs ||= FileSystem.instance
      end
    end
  end
end
