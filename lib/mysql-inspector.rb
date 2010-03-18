require "fileutils"

module MysqlInspector

  Precondition = Class.new(StandardError)

  module Config
    extend self

    def mysqldump(*args)
      all_args = ["-u #{mysql_user}"] + args
      Command.new(mysqldump_path, *all_args)
    end

    def mysql_user
      @mysql_user ||= "root"
    end

    def mysqldump_path
      @mysqldump_path ||= begin
        path = `which mysqldump`.chomp
        raise Precondition, "mysqldump was not in your path" if path.empty?
        path
      end
    end
  end

  class Command
    def initialize(path, *args)
      @path = path
      @args = args
    end
    def to_s
      "#{@path} #{@args * " "}"
    end
    def run!
      system to_s
    end
  end

  class Dump
    def initialize(version, base_dir)
      @version = version
      @base_dir = base_dir
      # TODO: sanity check base_dir for either a relative dir or /tmp/...
    end

    attr_reader :version, :base_dir

    def db_date
      @db_date ||= read_db_date
    end

    def dir
      File.join(base_dir, version)
    end

    def clean!
      FileUtils.rm_rf(dir)
    end

    def exists?
      File.exist?(dir)
    end

    def dump!(db_name)
      raise Precondition, "Can't overwrite an existing schema at #{dir.inspect}" if exists?
      FileUtils.mkdir_p(dir)
      Config.mysqldump("--no-data", "-T #{dir}", "--skip-opt", db_name).run!
      File.open(info_file, "w") { |f| f.puts(Time.now.utc.strftime("%Y-%m-%d")) }
    end

  protected

    def info_file
      File.join(dir, ".info")
    end

    def read_db_date
      raise Precondition, "No dump exists at #{dir.inspect}" unless File.exist?(info_file)
      File.read(info_file).strip
    end
  end

  module Utils

    def file_to_table(file)
      file[/(.*)\.sql/, 1]
    end

    def sanitize_schema!(schema)
      schema.collect! { |line| line.rstrip[/(.*?),?$/, 1] }
      schema.delete_if { |line| line =~ /(\/\*|--|CREATE TABLE)/ or line == ");" or line.strip.empty? }
      schema.sort!
      schema
    end
  end

  class Grep
    include Utils

    def initialize(dump)
      @dump = dump
    end

    attr_reader :dump

    def find(writer, *matchers)
      writer.puts
      writer.puts "Searching #{dump.version} (#{dump.db_date}) for #{matchers.inspect}"
      writer.puts
      files = Dir[File.join(dump.dir, "*.sql")].collect { |f| File.basename(f) }.sort
      files.each do |f|
        schema = File.read(File.join(dump.dir, f)).split("\n")
        sanitize_schema!(schema)

        matches = schema.select do |line|
          matchers.all? do |matcher|
            col, *items = matcher.split(/\s+/)
            col = "`#{col}`"
            [col, items].flatten.all? { |item| line.downcase =~ /#{Regexp.escape item.downcase}/ }
          end
        end

        if matches.any?
        writer.puts
          writer.puts file_to_table(f)
          writer.puts "*" * file_to_table(f).size
          writer.puts
          writer.puts "Found matching:"
          writer.puts matches.join("\n")
          writer.puts
          writer.puts "Full schema:"
          writer.puts schema.join("\n")
        writer.puts
        end
      end
    end
  end

  class Comparison
    include Utils

    def initialize(current, target)
      @current = current
      @target = target
    end

    attr_reader :current, :target

    def ignore_files
      ["migration_info.sql"]
    end

    def compare(writer=STDOUT)
      writer.puts
      writer.puts "Current: #{current.version} (#{current.db_date})"
      writer.puts "Target:  #{target.version} (#{target.db_date})"

      current_files = Dir[File.join(current.dir, "*.sql")].collect { |f| File.basename(f) }.sort
      target_files = Dir[File.join(target.dir, "*.sql")].collect { |f| File.basename(f) }.sort

      # Ignore some tables
      current_files -= ignore_files
      target_files -= ignore_files

      files_only_in_target = target_files - current_files
      files_only_in_current = current_files - target_files
      common_files = target_files & current_files

      if files_only_in_current.any?
        writer.puts
        writer.puts "Tables only in current"
        writer.puts files_only_in_current.collect { |f| file_to_table(f) }.join(", ")
      end

      if files_only_in_target.any?
        writer.puts
        writer.puts "Tables in target but not in current"
        writer.puts files_only_in_target.collect { |f| file_to_table(f) }.join(", ")
      end

      common_files.each do |f|
        current_schema = File.read(File.join(current.dir, f)).split("\n")
        target_schema = File.read(File.join(target.dir, f)).split("\n")

        sanitize_schema!(current_schema)
        sanitize_schema!(target_schema)

        next if current_schema == target_schema

        writer.puts
        writer.puts file_to_table(f)
        writer.puts "*" * file_to_table(f).size
        writer.puts

        only_in_target = target_schema - current_schema
        only_in_current = current_schema - target_schema

        if only_in_current.any?
          writer.puts "only in current"
          writer.puts only_in_current.join("\n")
          writer.puts
        end
        if only_in_target.any?
          writer.puts "only in target"
          writer.puts only_in_target.join("\n")
          writer.puts
        end
      end
    end

  end

end