module MysqlInspector
  class Dump

    WriteError = Class.new(StandardError)

    def initialize(dir, db_name)
      # TODO: sanity check dir for either a relative dir or /tmp/...
      @dir = dir
      @db_name = db_name
      @info_file = File.join(dir, ".info")
    end

    # Public: Get the dump directory.
    #
    # Returns a String.
    attr_reader :dir

    # Public: Get the name of the database being dumped.
    #
    # Returns a String.
    attr_reader :db_name

    # Public: Get the time that this dump was created.
    #
    # Returns a Time
    def timestamp
      if exists?
        Time.parse(File.read(@info_file).strip)
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
    # Returns nothing.
    def write!
      clean! if exists?
      FileUtils.mkdir_p(dir)
      command = Runner.mysqldump("--no-data", "-T #{dir}", "--skip-opt", @db_name)
      begin
        command.run!
      rescue Runner::CommandError => e
        case e.message
        when /1049: Unknown database/
          raise WriteError, "The database #{@db_name} does not exist"
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
      Dir[File.join(dir, "*.sql")].map do |file|
        schema = File.read(file)
        Table.new(@db_name, schema)
      end
    end

  end
end
