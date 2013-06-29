require 'memfs/fake/entry'

module MemFs
  module Fake
    class Directory < Entry
      attr_accessor :entries

      def initialize(*args)
        super
        self.entries = { '.' => self, '..' => nil }
      end

      def add_entry(entry)
        entries[entry.name] = entry
        entry.parent = self
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

      def parent=(parent)
        super
        entries['..'] = parent
      end

      def remove_entry(entry)
        entries.delete(entry.name)
      end

      def path
        name == '/' ? '/' : super
      end

      def empty?
        (entries.keys - %w[. ..]).empty?
      end
    end
  end
end
