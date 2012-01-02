module MysqlInspector
  class Index < Struct.new(:name, :column_names, :uniqe)

  end
end