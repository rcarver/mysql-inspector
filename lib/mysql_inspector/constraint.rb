module MysqlInspector
  class Constraint < Struct.new(:name, :column_names, :foreign_table, :foreign_column_names, :on_update, :on_delete)

    include MysqlInspector::TablePart

    def =~(matcher)
      name =~ matcher ||
        column_names.any? { |c| c =~ matcher } ||
        foreign_table =~ matcher ||
        foreign_column_names.any? { |c| c =~ matcher }
    end

  end
end
