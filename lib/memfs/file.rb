require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  class File
    extend FilesystemAccess
    extend SingleForwardable
    include FilesystemAccess

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

    SUCCESS = 0

    def_delegators :original_file_class,
                   :basename,
                   :dirname,
                   :extname,
                   :fnmatch,
                   :join,
                   :path

    def self.absolute_path(path, dir_string = nil)
      basedir = dir_string || Dir.pwd
      original_file_class.absolute_path(path, basedir)
    end

    def self.atime(path)
      stat(path).atime
    end

    def self.chmod(mode_int, *paths)
      paths.each do |path|
        fs.chmod mode_int, path
      end
    end

    def self.chown(uid, gid, *paths)
      paths.each do |path|
        fs.chown(uid, gid, path)
      end
      paths.size
    end

    def self.ctime(path)
      stat(path).ctime
    end

    def self.directory?(path)
      fs.directory? path
    end

    def self.executable?(path)
      fs.find(path) && stat(path).executable?
    end

    def self.executable_real?(path)
      fs.find(path) && stat(path).executable_real?
    end

    def self.exists?(path)
      not fs.find(path).nil?
    end
    class << self; alias :exist? :exists?; end

    def self.expand_path(file_name, dir_string = fs.pwd)
      original_file_class.expand_path(file_name, dir_string)
    end

    def self.file?(path)
      fs.find(path).is_a?(Fake::File)
    end

    class << self; alias :fnmatch? :fnmatch; end

    def self.grpowned?(path)
      fs.find(path) && stat(path).grpowned?
    end

    def self.identical?(path1, path2)
      fs.find!(path1).dereferenced === fs.find!(path2).dereferenced
    rescue Errno::ENOENT
      false
    end

    def self.lchmod(mode_int, *file_names)
      file_names.each do |file_name|
        fs.chmod mode_int, file_name
      end
    end

    def self.lchown(uid, gid, *paths)
      chown uid, gid, *paths
    end

    def self.link(old_name, new_name)
      fs.link old_name, new_name
      SUCCESS
    end

    def self.lstat(path)
      Stat.new(path)
    end

    def self.mtime(path)
      stat(path).mtime
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

    def self.owned?(path)
      fs.find(path) && stat(path).owned?
    end

    def self.read(path, length = nil, offset = 0, mode: RDONLY, encoding: nil, open_args: nil)
      open_args ||= [mode, encoding: encoding]

      file = open(path, *open_args)
      file.seek(offset)
      file.read(length)
    ensure
      file.close if file
    end

    def self.readable?(path)
      fs.find(path) && stat(path).readable?
    end

    def self.readable_real?(path)
      fs.find(path) && stat(path).readable_real?
    end

    def self.readlink(path)
      fs.find!(path).target
    end

    def self.rename(old_name, new_name)
      fs.rename(old_name, new_name)
      SUCCESS
    end

    def self.reset!
      @umask = original_file_class.umask
    end

    def self.size(path)
      fs.find!(path).size
    end

    def self.size?(path)
      file = fs.find(path)
      file && file.size > 0 && file.size
    end

    def self.stat(path)
      Stat.new(path, true)
    end

    def self.sticky?(path)
      fs.find(path) && stat(path).sticky?
    end

    def self.symlink(old_name, new_name)
      fs.symlink old_name, new_name
      SUCCESS
    end

    def self.symlink?(path)
      fs.symlink? path
    end

    def self.umask(integer = nil)
      old_value = @umask || original_file_class.umask

      @umask = integer if integer

      old_value
    end

    def self.unlink(*paths)
      paths.each do |path|
        fs.unlink(path)
      end
      paths.size
    end
    class << self; alias :delete :unlink; end

    def self.utime(atime, mtime, *file_names)
      file_names.each do |file_name|
        fs.find!(file_name).atime = atime
        fs.find!(file_name).mtime = mtime
      end
      file_names.size
    end

    def self.writable?(path)
      fs.find(path) && stat(path).writable?
    end

    def self.writable_real?(path)
      fs.find(path) && stat(path).writable_real?
    end

    attr_accessor :closed,
                  :entry,
                  :opening_mode
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

    def chmod(mode_int)
      fs.chmod(mode_int, path)
      SUCCESS
    end

    def chown(uid, gid = nil)
      fs.chown(uid, gid, path)
      SUCCESS
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

    def lstat
      File.lstat(path)
    end

    def pos
      entry.pos
    end

    def puts(text)
      raise IOError, 'not opened for writing' unless writable?

      content.puts text
    end

    def read(length = nil, buffer = '')
      default = length ? nil : ''
      content.read(length, buffer) || default
    end

    def seek(amount, whence = IO::SEEK_SET)
      new_pos = case whence
      when IO::SEEK_CUR then entry.pos + amount
      when IO::SEEK_END then content.to_s.length + amount
      when IO::SEEK_SET then amount
      end

      if new_pos.nil? || new_pos < 0
        raise Errno::EINVAL, path
      end

      entry.pos = new_pos and 0
    end

    def size
      entry.size
    end

    def stat
      File.stat(path)
    end

    def write(string)
      raise IOError, 'not opened for writing' unless writable?

      content.write(string.to_s)
    end

    private

    def self.original_file_class
      MemFs::OriginalFile
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
  end
end
