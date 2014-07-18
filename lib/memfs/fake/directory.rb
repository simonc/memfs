require 'memfs/fake/entry'

module MemFs
  module Fake
    class Directory < Entry
      attr_accessor :entries

      def add_entry(entry)
        entries[entry.name] = entry
        entry.parent = self
      end

      def empty?
        (entries.keys - %w[. ..]).empty?
      end

      def entry_names
        entries.keys
      end

      def find(path)
        path = path.sub(/\A\/+/, '')
        parts = path.split('/', 2)

        if entry_names.include?(path)
          entries[path]
        elsif entry_names.include?(parts.first)
          entries[parts.first].find(parts.last)
        end
      end

      def initialize(*args)
        super
        self.entries = { '.' => self, '..' => nil }
      end

      def parent=(parent)
        super
        entries['..'] = parent
      end

      def path
        name == '/' ? '/' : super
      end

      def paths
        [path] + entries.reject { |p| %w[. ..].include?(p) }.values.map(&:paths).flatten
      end

      def remove_entry(entry)
        entries.delete(entry.name)
      end

      def type
        'directory'
      end
    end
  end
end
