module MysqlInspector
  class Constraint < Struct.new(:name, :column_names, :foreign_table, :foreign_column_names, :on_update, :on_delete)

  end
end