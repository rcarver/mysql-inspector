module MysqlInspector
  class Column < Struct.new(:name, :sql_type, :nullable, :default)

    def =~(matcher)
      name =~ matcher
    end

  end
end