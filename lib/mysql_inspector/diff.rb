module MysqlInspector
  class Diff

    def initialize(current_dump, target_dump)
      @current_dump = current_dump
      @target_dump = target_dump
    end

    attr_reader :added_tables
    attr_reader :missing_tables
    attr_reader :equal_tables
    attr_reader :different_tables

    def execute
      @added_tables = []
      @missing_tables = []
      @equal_tables = []
      @different_tables = []

      target_tables = Hash[*@target_dump.tables.map { |t| [t.table_name, t] }.flatten]
      current_tables = Hash[*@current_dump.tables.map { |t| [t.table_name, t] }.flatten]

      (target_tables.keys + current_tables.keys).uniq.each { |n|
        target = target_tables[n]
        current = current_tables[n]
        if target && current
          if target == current
            @equal_tables << target
          else
            @different_tables << TableDiff.new(target, current)
          end
        else
          @added_tables << target if target_tables.has_key?(n)
          @missing_tables << current if current_tables.has_key?(n)
        end
      }
    end

  protected

    class TableDiff

      def initialize(target_table, current_table)
        @target_table = target_table
        @current_table = current_table
      end

      def table_name
        @target_table.table_name
      end

      def added_columns
        @target_table.columns - @current_table.columns
      end

      def missing_columns
        @current_table.columns - @target_table.columns
      end

      def added_indices
        @target_table.indices - @current_table.indices
      end

      def missing_indices
        @current_table.indices - @target_table.indices
      end

      def added_constraints
        @target_table.constraints - @current_table.constraints
      end

      def missing_constraints
        @current_table.constraints - @target_table.constraints
      end
    end

  end
end
