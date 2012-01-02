module MysqlInspector
  class Column < Struct.new(:name, :sql_type, :nullable, :default)

  end
end