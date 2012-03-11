module MysqlInspector
  module AR
    class Dump < MysqlInspector::Dump

      def migrations_table_name
        "schema_migrations"
      end

      def migrations_column
        "version"
      end

      # Public: Get the migrations to load into the migrations table.
      #
      # Returns an Array of String.
      def migrations
        file = File.join(dir, "#{migrations_table_name}.tsv")
        if File.exist?(file)
          File.readlines(file).map { |line| line.chomp }
        else
          []
        end
      end

      def write!(access)
        super
        migrations = access.read_migrations(migrations_table_name)
        File.open(File.join(dir, "#{migrations_table_name}.tsv"), "w") { |f|
          f.puts migrations.sort.join("\n")
        }
      end

      def load!(access)
        super
        access.write_migrations(migrations_table_name, migrations_column, migrations)
      end

    end
  end
end
