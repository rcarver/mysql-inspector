module MysqlInspector
  class Constraint < Struct.new(:name, :column_names, :foreign_table, :foreign_column_names, :on_update, :on_delete)

    include MysqlInspector::TablePart

    def to_sql
      parts = []
      parts << "CONSTRAINT"
      parts << quote(name)
      parts << "FOREIGN KEY"
      parts << paren(column_names.map { |c| quote(c) })
      parts << "REFERENCES"
      parts << quote(foreign_table)
      parts << paren(foreign_column_names.map { |c| quote(c) })
      parts << "ON DELETE #{on_delete}"
      parts << "ON UPDATE #{on_update}"
      parts * " "
    end

    def =~(matcher)
      name =~ matcher ||
        column_names.any? { |c| c =~ matcher } ||
        foreign_table =~ matcher ||
        foreign_column_names.any? { |c| c =~ matcher }
    end

  end
end
