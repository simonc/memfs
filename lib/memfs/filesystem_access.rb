module MemFs
  module FilesystemAccess
    def fs
      FileSystem.instance
    end
  end
end
