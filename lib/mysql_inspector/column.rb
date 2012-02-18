module MysqlInspector
  class Column < Struct.new(:name, :sql_type, :nullable, :default, :auto_increment)

    include MysqlInspector::TablePart

    def to_sql
      parts = []
      parts << quote(name)
      parts << sql_type
      parts << (nullable ? "NULL" : "NOT NULL")
      parts << "DEFAULT #{default}" if default
      parts << "AUTO_INCREMENT" if auto_increment
      parts * " "
    end

    def =~(matcher)
      name =~ matcher
    end

  end
end
