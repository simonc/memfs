require 'forwardable'
require 'memfs/filesystem_access'
require 'memfs/io'

module MemFs
  class File
    extend FilesystemAccess
    extend SingleForwardable
    extend IO::ClassMethods

    include Enumerable
    include FilesystemAccess
    include OriginalFile::Constants
    include IO::InstanceMethods

    ALT_SEPARATOR = nil

    MODE_MAP = {
      'r'  => RDONLY,
      'r+' => RDWR,
      'w'  => CREAT | TRUNC | WRONLY,
      'w+' => CREAT | TRUNC | RDWR,
      'a'  => CREAT | APPEND | WRONLY,
      'a+' => CREAT | APPEND | RDWR
    }

    SEPARATOR = '/'
    SUCCESS = 0

    @umask = nil

    def_delegators :original_file_class,
                   :basename,
                   :dirname,
                   :extname,
                   :fnmatch,
                   :join,
                   :path,
                   :split

    [
      :blockdev?,
      :chardev?,
      :directory?,
      :executable?,
      :executable_real?,
      :file?,
      :grpowned?,
      :owned?,
      :pipe?,
      :readable?,
      :readable_real?,
      :setgid?,
      :setuid?,
      :socket?,
      :sticky?,
      :writable?,
      :writable_real?,
      :zero?
    ].each do |query_method|
      define_singleton_method(query_method) do |path|    # def directory?(path)
        stat_query(path, query_method)                   #   stat_query(path, :directory?)
      end                                                # end
    end

    [
      :world_readable?,
      :world_writable?
    ].each do |query_method|
      define_singleton_method(query_method) do |path|    # def directory?(path)
        stat_query(path, query_method, false)            #   stat_query(path, :directory?, false)
      end                                                # end
    end

    def self.absolute_path(path, dir_string = fs.pwd)
      original_file_class.absolute_path(path, dir_string)
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

    def self.exists?(path)
      !!fs.find(path)
    end
    class << self; alias_method :exist?, :exists?; end

    def self.expand_path(file_name, dir_string = fs.pwd)
      original_file_class.expand_path(file_name, dir_string)
    end

    def self.ftype(path)
      fs.find!(path) && lstat(path).ftype
    end

    class << self; alias_method :fnmatch?, :fnmatch; end

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
      file = new(filename, mode, *perm_and_opt)

      if block_given?
        yield file
      else
        file
      end
    ensure
      file.close if file && block_given?
    end

    def self.readlink(path)
      fs.find!(path).target
    end

    def self.realdirpath(path, dir_string = fs.pwd)
      loose_dereference_path(absolute_path(path, dir_string))
    end

    def self.realpath(path, dir_string = fs.pwd)
      dereference_path(absolute_path(path, dir_string))
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
      if file && file.size > 0
        file.size
      else
        false
      end
    end

    def self.stat(path)
      Stat.new(path, true)
    end

    def self.symlink(old_name, new_name)
      fs.symlink old_name, new_name
      SUCCESS
    end

    def self.symlink?(path)
      lstat_query(path, :symlink?)
    end

    def self.truncate(path, length)
      fs.find!(path).content.truncate(length)
      SUCCESS
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
    class << self; alias_method :delete, :unlink; end

    def self.utime(atime, mtime, *file_names)
      file_names.each do |file_name|
        fs.find!(file_name).atime = atime
        fs.find!(file_name).mtime = mtime
      end
      file_names.size
    end

    attr_reader :path

    def initialize(filename, mode = File::RDONLY, *perm_and_or_opt)
      opt = perm_and_or_opt.last.is_a?(Hash) ? perm_and_or_opt.pop : {}
      perm = perm_and_or_opt.shift
      if perm_and_or_opt.size > 0
        fail ArgumentError, 'wrong number of arguments (4 for 1..3)'
      end

      @path = filename
      @external_encoding = opt[:external_encoding] && Encoding.find(opt[:external_encoding])

      self.closed = false
      self.opening_mode = str_to_mode_int(mode)

      fs.touch(filename) if create_file?

      self.entry = fs.find(filename)

      entry.content.clear if truncate_file?
    end

    def atime
      File.atime(path)
    end

    def chmod(mode_int)
      fs.chmod(mode_int, path)
      SUCCESS
    end

    def chown(uid, gid = nil)
      fs.chown(uid, gid, path)
      SUCCESS
    end

    def ctime
      File.ctime(path)
    end

    def flock(*)
      SUCCESS
    end

    def mtime
      File.mtime(path)
    end

    def lstat
      File.lstat(path)
    end

    def size
      entry.size
    end

    def truncate(integer)
      File.truncate(path, integer)
    end

    private

    def self.dereference_name(path)
      entry = fs.find(path)
      if entry
        entry.dereferenced_name
      else
        basename(path)
      end
    end
    private_class_method :dereference_name

    def self.dereference_dir_path(path)
      dereference_path(dirname(path))
    end
    private_class_method :dereference_dir_path

    def self.dereference_path(path)
      fs.find!(path).dereferenced_path
    end
    private_class_method :dereference_path

    def self.loose_dereference_path(path)
      join(dereference_dir_path(path), dereference_name(path))
    end
    private_class_method :loose_dereference_path

    def self.original_file_class
      MemFs::OriginalFile
    end
    private_class_method :original_file_class

    def self.stat_query(path, query, force_boolean = true)
      response = fs.find(path) && stat(path).public_send(query)
      force_boolean ? !!(response) : response
    end
    private_class_method :stat_query

    def self.lstat_query(path, query)
      response = fs.find(path) && lstat(path).public_send(query)
      !!(response)
    end
    private_class_method :lstat_query
  end
end
