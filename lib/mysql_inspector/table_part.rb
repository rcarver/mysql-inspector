module MysqlInspector
  module TablePart

    attr_accessor :table
    attr_accessor :sql_line

    def <=>(other)
      name <=> other.name
    end

    def to_s
      sql_line.strip.chomp(',')
    end

  end
end
