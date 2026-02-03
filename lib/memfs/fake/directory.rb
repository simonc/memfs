# frozen_string_literal: true

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

      # rubocop:disable Metrics/AbcSize
      def find(path)
        path = MemFs.normalize_path(path)

        # Strip root prefix if present - check platform_root first, then directory name for root dirs
        if path.start_with?(MemFs.platform_root)
          path = path[MemFs.platform_root.length..]
        elsif root_directory? && path.start_with?(name)
          path = path[name.length..]
        end

        path = path.gsub(%r{(\A/+|/+\z)}, '')
        return self if path.empty?

        parts = path.split('/', 2)

        if entry_names.include?(path)
          entries[path]
        elsif entry_names.include?(parts.first)
          entries[parts.first].find(parts.last)
        end
      end
      # rubocop:enable Metrics/AbcSize

      def initialize(*args)
        super
        self.entries = { '.' => self, '..' => nil }
      end

      def parent=(parent)
        super
        entries['..'] = parent
      end

      def path
        root_directory? ? name : super
      end

      def paths
        current_or_parent_dirs = %w[. ..]

        [path] +
          entries
          .reject { current_or_parent_dirs.include?(_1) }
          .values
          .map(&:paths)
          .flatten
      end

      def remove_entry(entry)
        entries.delete(entry.name)
      end

      def type
        'directory'
      end

      private

      def root_directory?
        parent.nil? || MemFs.root_path?(name)
      end
    end
  end
end
