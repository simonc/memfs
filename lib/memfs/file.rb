require 'forwardable'
require 'memfs/filesystem_access'

module MemFs
  class File
    extend FilesystemAccess
    extend SingleForwardable
    include Enumerable
    include FilesystemAccess
    include OriginalFile::Constants

    MODE_MAP = {
      'r'  => RDONLY,
      'r+' => RDWR,
      'w'  => CREAT | TRUNC | WRONLY,
      'w+' => CREAT | TRUNC | RDWR,
      'a'  => CREAT | APPEND | WRONLY,
      'a+' => CREAT | APPEND | RDWR
    }

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

    def self.read(path, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options = { mode: RDONLY, encoding: nil, open_args: nil }.merge(options)
      open_args = options[:open_args] ||
                  [options[:mode], encoding: options[:encoding]]

      length, offset = args

      file = open(path, *open_args)
      file.seek(offset || 0)
      file.read(length)
    ensure
      file.close if file
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

    def initialize(filename, mode = RDONLY, *perm_and_or_opt)
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

    def each(sep = $/, &block)
      return to_enum(__callee__) unless block_given?
      fail IOError, 'not opened for reading' unless readable?
      content.each_line(sep) { |line| block.call(line) }
      self
    end

    def external_encoding
      writable? ? @external_encoding : Encoding.default_external
    end

    def lstat
      File.lstat(path)
    end

    def pos
      entry.pos
    end

    def puts(text)
      fail IOError, 'not opened for writing' unless writable?

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

      fail Errno::EINVAL, path if new_pos.nil? || new_pos < 0

      entry.pos = new_pos
      0
    end

    def size
      entry.size
    end

    def stat
      File.stat(path)
    end

    def write(string)
      fail IOError, 'not opened for writing' unless writable?

      content.write(string.to_s)
    end

    private

    attr_accessor :closed,
                  :entry,
                  :opening_mode

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

    def content
      entry.content
    end

    def str_to_mode_int(mode)
      return mode unless mode.is_a?(String)

      unless mode =~ /\A([rwa]\+?)([bt])?\z/
        fail ArgumentError, "invalid access mode #{mode}"
      end

      mode_str = $~[1]
      MODE_MAP[mode_str]
    end

    def create_file?
      (opening_mode & File::CREAT).nonzero?
    end

    def readable?
      (opening_mode & File::RDWR).nonzero? ||
      (opening_mode | File::RDONLY).zero?
    end

    def truncate_file?
      (opening_mode & File::TRUNC).nonzero?
    end

    def writable?
      (opening_mode & File::WRONLY).nonzero? ||
      (opening_mode & File::RDWR).nonzero?
    end
  end
end
