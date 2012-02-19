module MysqlInspector
  class Dump

    WriteError = Class.new(StandardError)

    def initialize(dir)
      @dir = dir
      @info_file = File.join(dir, ".info")
    end

    # Public: Get the dump directory.
    #
    # Returns a String.
    attr_reader :dir

    # Public: Get the time that this dump was created.
    #
    # Returns a Time
    def timestamp
      if exists?
        Time.parse(File.read(@info_file).strip)
      end
    end

    def db_name
      if exists?
        # FIXME: store db name in yaml info file
        "mysql_inspector_test"
      end
    end

    # Public: Delete this dump from the filesystem.
    #
    # Returns nothing.
    def clean!
      FileUtils.rm_rf(dir)
    end

    # Public: Determine if a dump currently exists at the dump directory.
    #
    # Returns a boolean.
    def exists?
      File.exist?(@info_file)
    end

    # Public: Write to the dump directory. Any existing dump will be deleted.
    #
    # database_name - String name of the database to store.
    #
    # Returns nothing.
    def write!(database_name)
      clean! if exists?
      FileUtils.mkdir_p(dir)
      begin
        writer = CliSchema.new(database_name)
        writer.write(dir)
      rescue CliSchema::Error => e
        FileUtils.rm_rf(dir) # note this does not remove all the dirs that may have been created.
        case e.message
        when /\s1049\s/
          raise WriteError, "The database #{database_name} does not exist"
        else
          raise WriteError, e.message
        end
      end
      File.open(@info_file, "w") { |f| f.print(Time.now.utc.to_s) }
    end

    # Public: Get the tables written by the dump.
    #
    # Returns an Array of MysqlInspector::Table.
    def tables
      Dir[File.join(dir, "*.table")].map do |file|
        schema = File.read(file)
        Table.new(schema)
      end
    end

    class CliSchema

      Error = Class.new(StandardError)

      def initialize(database_name)
        @database_name = database_name
      end

      def table_names
        pipe_to_mysql("SHOW TABLES")
      end

      def tables
        table_names.map { |table|
          output = pipe_to_mysql("SHOW CREATE TABLE #{table}")
          schema = output[0].split("\t").last.gsub(/\\n/, "\n")
          MysqlInspector::Table.new(schema)
        }
      end

      def write(dir)
        tables.each { |table| table.write(dir) }
      end

      def pipe_to_mysql(query)
        out, err, status = Open3.capture3("echo '#{query}' | mysql -uroot #{@database_name}")
        raise Error, err unless status.exitstatus == 0
        out.split("\n")[1..-1].map { |row| row.chomp }
      end
    end

  end
end
