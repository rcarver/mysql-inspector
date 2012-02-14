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
      (@columns + @indices + @constraints).any?
    end

  protected

    def find(parts)
      parts.find_all { |col|
        @matchers.all? { |m| col =~ m }
      }
    end

  end
end
