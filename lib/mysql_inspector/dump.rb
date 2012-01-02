module MysqlInspector
  class Dump

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
      raise Precondition, "No dump exists at #{dir.inspect}" unless exists?            
      Time.parse(File.read(@info_file).strip)
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
      Runner.mysqldump("--no-data", "-T #{dir}", "--skip-opt", @db_name).run!
      File.open(@info_file, "w") { |f| f.print(Time.now.utc.strftime("%Y-%m-%d")) }
    end

    # Public: Get the tables written by the dump.
    #
    # Returns an Array of MysqlInspector::Table.
    def tables
      Dir[File.join(dir, "*.sql")].map do |file|
        lines = File.readlines(file)
        Table.new(@db_name, Utils.file_to_table(file), lines)
      end
    end

  end
end
