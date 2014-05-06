module MemFs
  module FilesystemAccess
    private

    def fs
      FileSystem.instance
    end
  end
end
