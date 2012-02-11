module MysqlInspector
  module Utils

    # Transform a Mysql Dump file name into its table name.
    #
    # file - String name of the file.
    #
    # Returns a String.
    def self.file_to_table(file)
      file[/(.*)\.sql/, 1]
    end

  end
end
