module MysqlInspector
  class Table

    BACKTICK_WORD = /`([^`]+)`/
    BACKTICK_CSV = /\(([^\)]+)\)/
    REFERENCE_OPTION = /RESTRICT|CASCADE|SET NULL|NO ACTION/

    def initialize(db_name, schema)
      @db_name
      @schema = schema
      @lines = schema.split("\n")
      @lines.delete_if { |line| line =~ /(\/\*|--|ENGINE)/ or line == ");" or line.strip.empty? }
      @lines.sort!
    end

    # Public: Get the name of the database that defines this table.
    #
    # Returns a String.
    attr_reader :db_name

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
          nullable = line !~ /NOT NULL/
          default = line[/DEFAULT '([^']+)'/, 1]
          table_part line, MysqlInspector::Column.new(name, sql_type, nullable, default)
        end
      }.compact
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
      }.compact
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
      }.compact
    end

    def <=>(other)
      table_name <=> other.table_name
    end

  protected

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
