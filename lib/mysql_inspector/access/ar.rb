module MysqlInspector
  class Access

    class AR < MysqlInspector::Access

      def initialize(database_name, connection)
        @database_name = database_name
        @connection = connection
      end

      attr_reader :database_name
      attr_reader :connection

      def table_names
        tables.map { |t| t.table_name }
      end

      def tables
        dump = connection.structure_dump
        tables = dump.split(";").map { |schema|
          table = MysqlInspector::Table.new(schema)
          table if table.table_name
        }.compact
      end

      def drop_all_tables
        without_foreign_keys do
          names = table_names
          connection.execute("DROP TABLE #{names.join(',')}") if names.any?
        end
      end

      def load(schema)
        schema.split(";").each { |table|
          connection.execute(table)
        }
      end

      def read_from_table(table_name)
        connection.select_values("SELECT * FROM #{table_name}")
      end

      def write_to_table(table_name, cols, rows)
        values = rows.map { |value| "('#{value}')" }
        connection.execute("INSERT INTO #{table_name} (#{cols.join(',')}) VALUES #{values * ','}")
      end

    protected

      def without_foreign_keys
        begin
          connection.execute disable_foreign_keys
          yield
        ensure
          connection.execute enable_foreign_keys
        end
      end
    end

  end
end


