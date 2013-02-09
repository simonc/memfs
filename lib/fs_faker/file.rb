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
      'w'  => WRONLY,
      'w+' => CREAT|TRUNC|WRONLY,
      'a'  => APPEND|CREAT|WRONLY,
      'a+' => APPEND|CREAT|RDWR
    }

    def_delegator :original_file_class, :path

    def self.chmod(mode_int, file_name)
      fs.chmod mode_int, file_name
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

    # FIXME: ensure file is closed
    def self.open(filename, mode = 'r', *perm_and_opt)
      if mode == 'a'
        fs.touch(filename)
      end
      file = self.new(filename) #(filename, mode, *perm_and_opt)
    # 
      if block_given?
        yield file
      # else
    #     file
      end
    # ensure
    #   file.close if block_given?
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

    def initialize(filename, mode = RDONLY, perm = nil, opt = nil)
      unless opt.nil? || opt.is_a?(Hash)
        raise ArgumentError, "wrong number of arguments (4 for 1..3)"
      end

      mode = str_to_mode_int(mode) if mode.is_a?(String)

      # fs.touch(filename)
    end

    def close
      nil
    end

    private

    def self.original_file_class
      FsFaker::OriginalFile
    end

    def self.fs
      FileSystem.instance
    end

    def str_to_mode_int(mode)
      unless mode =~ /\A([rwa]\+?)([bt])?\z/
        raise ArgumentError, "invalid access mode #{mode}"
      end

      mode_str = $~[1]
      MODE_MAP[mode_str]
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

      private

      def fs
        FileSystem.instance
      end
    end
  end
end
