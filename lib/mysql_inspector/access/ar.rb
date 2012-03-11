module MysqlInspector
  class Access

    class AR < MysqlInspector::Access

      def initialize(connection)
        @connection = connection
      end

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
        connection.disable_referential_integrity do
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
    end

  end
end


