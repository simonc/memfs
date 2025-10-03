# frozen_string_literal: true

require 'memfs/filesystem_access'

module MemFs
  class Dir
    extend FilesystemAccess
    include Enumerable
    include FilesystemAccess

    attr_reader :pos

    def self.[](*patterns)
      glob(patterns)
    end

    def self.chdir(path, &block)
      fs.chdir path, &block
      0
    end

    if MemFs.ruby_version_gte?('2.6')
      def self.children(dirname, opts = {})
        entries(dirname, opts) - %w[. ..]
      end
    end

    def self.chroot(path)
      fail Errno::EPERM, path unless Process.uid.zero?

      dir = fs.find_directory!(path)
      dir.name = '/'
      fs.root = dir
      0
    end

    def self.empty?(path)
      entry = fs.find!(path)
      File.directory?(path) && entry.empty?
    end

    def self.entries(dirname, _opts = {})
      fs.entries(dirname)
    end

    def self.exists?(path)
      File.directory?(path)
    end
    class << self; alias exist? exists?; end

    def self.foreach(dirname, &block)
      return to_enum(__callee__, dirname) unless block

      entries(dirname).each(&block)
    end

    def self.getwd
      fs.getwd
    end
    class << self; alias pwd getwd; end

    def self.glob(patterns, flags = 0, &block)
      patterns = [*patterns].map(&:to_s)
      list = fs.paths.select do |path|
        patterns.any? do |pattern|
          File.fnmatch?(pattern, path, flags | GLOB_FLAGS)
        end
      end
      # FIXME: ugly special case for /* and /
      list.delete('/') if patterns.first == '/*'
      return list unless block_given?
      list.each(&block)
      nil
    end

    def self.home(*args)
      original_dir_class.home(*args)
    end

    def self.mkdir(path, mode = 0o777)
      fs.mkdir path, mode
    end

    def self.open(dirname)
      dir = new(dirname)

      if block_given?
        yield dir
      else
        dir
      end
    ensure
      dir&.close if block_given?
    end

    def self.rmdir(path)
      fs.rmdir path
    end

    def self.tmpdir
      '/tmp'
    end

    def self.mktmpdir(prefix_suffix = nil, tmpdir = nil, **options)
      tmpdir ||= self.tmpdir

      case prefix_suffix
      when nil
        prefix = 'd'
        suffix = ''
      when String
        prefix = prefix_suffix
        suffix = ''
      when Array
        prefix = prefix_suffix[0] || 'd'
        suffix = prefix_suffix[1] || ''
      else
        raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
      end

      max_try = options.fetch(:max_try, 10000)
      path = nil

      max_try.times do
        timestamp = Time.now.strftime('%Y%m%d')
        random = sprintf('%d-%d', $$, rand(0x100000000))
        path = File.join(tmpdir, "#{prefix}#{timestamp}-#{random}-0#{suffix}")

        begin
          mkdir(path, 0o700)
          break
        rescue Errno::EEXIST
          path = nil
          next
        end
      end

      raise "cannot generate temporary directory name" if path.nil?

      if block_given?
        begin
          result = yield path
        ensure
          begin
            rmdir(path) if exists?(path)
          rescue
            # Ignore cleanup errors
          end
        end
        result
      else
        path
      end
    end

    class << self
      alias delete rmdir
      alias unlink rmdir
    end

    def initialize(path)
      self.entry = fs.find_directory!(path)
      self.state = :open
      @pos = 0
      self.max_seek = 0
    end

    def close
      fail IOError, 'closed directory' if state == :closed
      self.state = :closed
    end

    def each(&block)
      return to_enum(__callee__) unless block
      entry.entry_names.each(&block)
    end

    def fileno
      entry.fileno
    end

    def path
      entry.path
    end
    alias to_path path

    # rubocop:disable Lint/Void
    def pos=(position)
      seek(position)
      position
    end
    # rubocop:enable Lint/Void

    def read
      name = entries[pos]
      @pos += 1
      self.max_seek = pos
      name
    end

    def rewind
      @pos = 0
      self
    end

    def seek(position)
      @pos = position if (0..max_seek).cover?(position)
      self
    end

    def tell
      @pos
    end

    GLOB_FLAGS = if defined?(File::FNM_EXTGLOB)
                   File::FNM_EXTGLOB | File::FNM_PATHNAME
                 else
                   File::FNM_PATHNAME
                 end
    private_constant :GLOB_FLAGS

    private

    attr_accessor :entry, :max_seek, :state

    def self.original_dir_class
      MemFs::OriginalDir
    end
    private_class_method :original_dir_class
  end
end
