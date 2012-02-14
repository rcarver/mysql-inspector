module MysqlInspector
  class Column < Struct.new(:name, :sql_type, :nullable, :default)

    include MysqlInspector::TablePart

    def =~(matcher)
      name =~ matcher
    end

  end
end
