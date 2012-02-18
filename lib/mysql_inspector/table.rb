module MysqlInspector
  class Table

    BACKTICK_WORD = /`([^`]+)`/
    BACKTICK_CSV = /\(([^\)]+)\)/
    REFERENCE_OPTION = /RESTRICT|CASCADE|SET NULL|NO ACTION/

    def initialize(schema)
      @schema = schema
      @lines = schema.split("\n")
      @lines.delete_if { |line| line =~ /(\/\*|--)/ or line.strip.empty? }
    end

    # Public: Get then name of the table.
    #
    # Returns a String.
    def table_name
      @table_name ||= begin
        line = @lines.find { |line| line =~ /CREATE TABLE #{BACKTICK_WORD}/}
        $1 if line
      end
    end

    # Public: Get all of the columns defined in the table.
    #
    # Returns an Array of MysqlInspector::Column.
    def columns
      @columns ||= @lines.map { |line|
        if line.strip =~ /^#{BACKTICK_WORD} ([\w\(\)\d]+)/
          name = $1
          sql_type = $2
          nullable = !!(line !~ /NOT NULL/)
          default = line[/DEFAULT ('?[^']+'?)/, 1]
          default = nil if default =~ /NULL/
          auto_increment = !!(line =~ /AUTO_INCREMENT/)
          table_part line, MysqlInspector::Column.new(name, sql_type, nullable, default, auto_increment)
        end
      }.compact.sort
    end

    # Public: Get all of the indices defined in the table
    #
    # Returns an Array of MysqlInspector::Index.
    def indices
      @indices ||= @lines.map { |line|
        if line.strip =~ /^(UNIQUE )?KEY #{BACKTICK_WORD} #{BACKTICK_CSV}/
          unique = !!$1
          name = $2
          column_names = backtick_names_in_csv($3)
          table_part line, MysqlInspector::Index.new(name, column_names, unique)
        end
      }.compact.sort
    end

    # Public: Get all of the constraints defined in the table
    #
    # Returns an Array of MysqlInspector::Constraint.
    def constraints
      @constraints ||= @lines.map { |line|
        if line.strip =~ /^CONSTRAINT #{BACKTICK_WORD} FOREIGN KEY #{BACKTICK_CSV} REFERENCES #{BACKTICK_WORD} #{BACKTICK_CSV} ON DELETE (#{REFERENCE_OPTION}) ON UPDATE (#{REFERENCE_OPTION})$/
          name = $1
          column_names = backtick_names_in_csv($2)
          foreign_name = $3
          foreign_column_names = backtick_names_in_csv($4)
          on_delete = $5
          on_update = $6
          table_part line, MysqlInspector::Constraint.new(name, column_names, foreign_name, foreign_column_names, on_update, on_delete)
        end
      }.compact.sort
    end

    def options
      @options ||= begin
        if line = @lines.find { |line| line =~ /ENGINE=/}
          # AUTO_INCREMENT is not useful.
          line.sub!(/AUTO_INCREMENT=\d+/, '')
          # Compact multiple spaces.
          line.gsub!(/\s+/, ' ')
          # Remove paren at the beginning.
          line.sub!(/^\)\s*/, '')
          # Remove semicolon at the end.
          line.chomp!(';')
          line
        end
      end
    end

    def eql?(other)
      table_name == other.table_name &&
          columns == other.columns &&
          indices == other.indices &&
          constraints == other.constraints &&
          options = other.options
    end

    alias == eql?

    def <=>(other)
      table_name <=> other.table_name
    end

    def to_simple_schema
      lines = []

      lines << "CREATE TABLE `#{table_name}`"
      lines << nil
      simple_schema_items(lines, columns)
      simple_schema_items(lines, indices)
      simple_schema_items(lines, constraints)
      lines << options

      lines.join("\n")
    end

    def to_sql
      lines = []

      lines << "CREATE TABLE `#{table_name}` ("
      lines << (columns + indices + constraints).map { |x| "  #{x.to_sql}" }.join(",\n")
      lines << ") #{options}"

      lines.join("\n")
    end

  protected

    def simple_schema_items(lines, items)
      lines.concat items.map { |item| item.to_sql }
      lines << nil if items.any?
    end

    def table_part(line, part)
      part.table = self
      part.sql_line = line
      part
    end

    def backtick_names_in_csv(string)
      string.split(',').map { |x| x[BACKTICK_WORD, 1] }
    end

  end
end
