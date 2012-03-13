module MysqlInspector
  class Migrations

    def initialize(dir)
      @dir = dir
    end

    def write!(access)
      migrations = access.read_migrations(migrations_table_name)
      File.open(File.join(@dir, "#{migrations_table_name}.tsv"), "w") { |f|
        f.puts migrations.sort.join("\n")
      }
    end

    def load!(access)
      access.write_migrations(migrations_table_name, migrations_column, migrations)
    end

    def migrations_table_name
      "schema_migrations"
    end

    def migrations_column
      "version"
    end

    def migrations
      file = File.join(@dir, "#{migrations_table_name}.tsv")
      if File.exist?(file)
        File.readlines(file).map { |line| line.chomp }
      else
        []
      end
    end

  end
end
