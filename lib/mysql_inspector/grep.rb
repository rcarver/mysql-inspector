module MysqlInspector
  class Grep

    def initialize(dump, matchers)
      @dump = dump
      @matchers = matchers
      @columns = []
      @indices = []
      @constraints = []
    end

    attr_reader :columns
    attr_reader :indices
    attr_reader :constraints

    def execute
      @columns = []
      @indices = []
      @constraints = []
      @dump.tables.each { |table|
        @columns.concat find(table.columns)
        @indices.concat find(table.indices)
        @constraints.concat find(table.constraints)
      }
      @columns.sort!
      @indices.sort!
      @constraints.sort!
    end

    def any_matches?
      (columns + indices + constraints).any?
    end

    def tables
      (columns + indices + constraints).map { |x| x.table }.uniq.sort
    end

    def each_table
      tables.each { |t| yield t, in_table(t) }
    end

    class Subset < Struct.new(:columns, :indices, :constraints)
      def any_matches?
        (columns + indices + constraints).any?
      end
    end

    def in_table(table)
      Subset.new(
        @columns.find_all { |c| c.table == table },
        @indices.find_all { |i| i.table == table },
        @constraints.find_all { |c| c.table == table }
      )
    end

  protected

    def find(parts)
      parts.find_all { |col|
        @matchers.all? { |m| col =~ m }
      }
    end

  end
end
