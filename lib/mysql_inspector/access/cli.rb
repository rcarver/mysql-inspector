module MysqlInspector
  class Access

    class CLI < MysqlInspector::Access

      def table_names
        rows_from pipe_to_mysql("SHOW TABLES")
      end

      def tables
        table_names.map { |table|
          rows = rows_from pipe_to_mysql("SHOW CREATE TABLE #{table}")
          schema = rows[0].split("\t").last.gsub(/\\n/, "\n")
          MysqlInspector::Table.new(schema)
        }
      end

      def drop_all_tables
        pipe_to_mysql without_foreign_keys("DROP TABLE #{table_names.join(',')}")
      end

      def load(schema)
        pipe_to_mysql without_foreign_keys(schema)
      end

    protected

      def without_foreign_keys(query)
        [disable_foreign_keys, query, enable_foreign_keys].join(";\n")
      end

      def pipe_to_mysql(query)
        mysql_command = MysqlInspector.config.mysql_command
        out, err, status = nil
        Tempfile.open('schema') do |file|
          file.print(query)
          file.flush
          out, err, status = Open3.capture3("cat #{file.path} | #{mysql_command} #{@database_name}")
        end
        unless status.exitstatus == 0
          case err
          when /\s1049\s/
            raise Error, "The database #{database_name} does not exist"
          else
            raise Error, err
          end
        end
        out
      end

      def rows_from(output)
        (output.split("\n")[1..-1] || []).map { |row| row.chomp }
      end
    end

  end
end

