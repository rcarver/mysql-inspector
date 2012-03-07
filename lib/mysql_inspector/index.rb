module MysqlInspector
  class Index < Struct.new(:name, :column_names, :unique)

    include MysqlInspector::TablePart

    def to_sql
      parts = []
      if name.nil? && unique
        parts << "PRIMARY KEY"
        parts << paren(column_names.map { |c| quote(c) })
      else
        parts << "UNIQUE" if unique
        parts << "KEY"
        parts << quote(name)
        parts << paren(column_names.map { |c| quote(c) })
      end
      parts * " "
    end

    def =~(matcher)
      name =~ matcher || column_names.any? { |c| c =~ matcher }
    end

  end
end
