module MysqlInspector

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
        raise "mysqldump was not in your path" if path.empty?
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
      "#{@path} #{args * " "}"
    end
    def run!
      system to_s
    end
  end

  class Dump
    def initialize(db_name, version, base_dir)
      @db_name = db_name
      @version = version
      @base_dir = base_dir
    end
    def dir
      File.join(@base_dir, @version)
    end
    def mkdir
      FileUtils.mkdir_p(dir)
    end
    def command
      Config.mysqldump("--no-data", "-T #{dir}", "--skip-opt", @db_name)
    end
    def run!
      mkdir
      command.run!
    end
  end

  class Comparison
    def initialize(current, target)
      @current = current
      @target = target
    end

    attr_reader :current, :target

    def ignore_files
      ["migration_info.sql"]
    end

    def compare(writer=STDOUT)
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
        writer.puts
      end

      if files_only_in_target.any?
        writer.puts "Tables in target but not in current"
        writer.puts files_only_in_target.collect { |f| file_to_table(f) }.join(", ")
        writer.puts
      end

      common_files.each do |f|
        current_schema = File.read(File.join(current.dir, f)).split("\n")
        target_schema = File.read(File.join(target.dir, f)).split("\n")

        sanitize_schema!(current_schema)
        sanitize_schema!(target_schema)

        next if current_schema == target_schema

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

    def file_to_table(file)
      file[/(.*)\.sql/, 1]
    end

    def sanitize_schema!(schema)
      schema.delete_if { |line| line =~ /(\/\*|--)/ }
      schema.collect! { |line| line.rstrip[/(.*?),?$/, 1] }
      schema.sort!
      schema
    end
  end

end