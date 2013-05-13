require 'forwardable'

module FsFaker
  class File
    extend SingleForwardable

    OriginalFile.constants.grep(/^[A-Z_]+$/).each do |const|
      const_set const, OriginalFile.const_get(const)
    end

    MODE_MAP = {
      'r'  => RDONLY,
      'r+' => RDWR,
      'w'  => CREAT|TRUNC|WRONLY,
      'w+' => CREAT|TRUNC|RDWR,
      'a'  => CREAT|APPEND|WRONLY,
      'a+' => CREAT|APPEND|RDWR
    }

    def_delegator :original_file_class, :path

    def self.chmod(mode_int, *paths)
      paths.each do |path|
        fs.chmod mode_int, path
      end
    end

    def self.lchmod(mode_int, *file_names)
      file_names.each do |file_name|
        fs.chmod mode_int, file_name
      end
    end

    def self.directory?(path)
      fs.directory? path
    end

    def self.utime(atime, mtime, *file_names)
      file_names.each do |file_name|
        fs.find!(file_name).atime = atime
        fs.find!(file_name).mtime = mtime
      end
      file_names.size
    end

    def self.symlink(old_name, new_name)
      fs.symlink old_name, new_name
      0
    end

    def self.symlink?(path)
      fs.symlink? path
    end

    def self.stat(path)
      Stat.new(path, true)
    end

    def self.lstat(path)
      Stat.new(path)
    end

    def self.umask(integer = nil)
      old_value = @umask

      if integer
        @umask = integer
      end

      old_value
    end

    def self.atime(path)
      stat(path).atime
    end

    def self.mtime(path)
      stat(path).mtime
    end

    def self.reset!
      @umask = original_file_class.umask
    end

    def self.open(filename, mode = RDONLY, *perm_and_opt)
      file = self.new(filename, mode, *perm_and_opt)

      if block_given?
        yield file
      else
        file
      end
    ensure
      file.close if file && block_given?
    end

    def self.join(*args)
      original_file_class.join(*args)
    end

    def self.chown(uid, gid, *paths)
      paths.each do |path|
        fs.chown(uid, gid, path)
      end
      paths.size
    end

    def self.lchown(uid, gid, *paths)
      chown uid, gid, *paths
    end

    def self.size(path)
      fs.find!(path).content.size
    end

    def self.identical?(path1, path2)
      fs.find!(path1).last_target === fs.find!(path2).last_target
    rescue Errno::ENOENT
      false
    end

    def self.read(path, length = nil, offset = 0, mode: RDONLY, encoding: nil, open_args: nil)
      open_args ||= [mode, encoding: encoding]

      file = open(path, *open_args)
      file.seek(offset)
      file.read(length)
    ensure
      file.close if file
    end

    def self.expand_path(file_name, dir_string = fs.pwd)
      OriginalFile.expand_path(file_name, dir_string)
    end

    def self.basename(file_name, suffix = '')
      OriginalFile.basename(file_name, suffix)
    end

    attr_accessor :closed
    attr_accessor :entry
    attr_accessor :opening_mode
    attr_reader :path

    def initialize(filename, mode = RDONLY, perm = nil, opt = nil)
      unless opt.nil? || opt.is_a?(Hash)
        raise ArgumentError, "wrong number of arguments (4 for 1..3)"
      end

      @path = filename

      self.opening_mode = str_to_mode_int(mode)

      fs.touch(filename) if create_file?

      self.entry = fs.find(filename)
    end

    def close
      self.closed = true
    end

    def closed?
      closed
    end

    def content
      entry.content
    end

    def puts(text)
      unless writable?
        raise IOError, 'not opened for writing'
      end

      content.puts text
    end

    def read(length = nil, buffer = '')
      default = length ? nil : ''
      content.read(length, buffer) || default
    end

    def size
      content.size
    end

    def stat
      File.stat(path)
    end

    def write(string)
      content.write(string.to_s)
    end

    def seek(amount, whence = IO::SEEK_SET)
      new_pos = case whence
      when IO::SEEK_CUR then content.pos + amount
      when IO::SEEK_END then content.to_s.length + amount
      when IO::SEEK_SET then amount
      end

      if new_pos.nil? || new_pos < 0
        raise Errno::EINVAL, path
      end

      content.pos = new_pos and 0
    end

    def pos
      content.pos
    end

    private

    def self.original_file_class
      FsFaker::OriginalFile
    end

    def self.fs
      FileSystem.instance
    end

    def fs
      FileSystem.instance
    end

    def str_to_mode_int(mode)
      return mode unless mode.is_a?(String)

      unless mode =~ /\A([rwa]\+?)([bt])?\z/
        raise ArgumentError, "invalid access mode #{mode}"
      end

      mode_str = $~[1]
      MODE_MAP[mode_str]
    end

    def create_file?
      (opening_mode & File::CREAT).nonzero?
    end

    def writable?
      (opening_mode & File::WRONLY).nonzero? ||
      (opening_mode & File::RDWR).nonzero?
    end

    class Stat
      extend Forwardable

      attr_reader :entry

      def initialize(path, follow_symlink = false)
        @path  = path
        @entry = fs.find!(path)
        @follow_symlink = follow_symlink
        follow_symlink && last_entry
      end

      def directory?
        File.directory? last_entry.path
      end

      def symlink?
        File.symlink? last_entry.path
      end

      def mode
        last_entry.mode
      end

      def atime
        last_entry.atime
      end

      def mtime
        last_entry.mtime
      end

      def uid
        last_entry.uid
      end

      def gid
        last_entry.gid
      end

      def last_entry
        if @follow_symlink && @entry.respond_to?(:last_target)
          @entry.last_target
        else
          @entry
        end
      end

      def blksize
        4096
      end

      private

      def fs
        FileSystem.instance
      end
    end
  end
end
