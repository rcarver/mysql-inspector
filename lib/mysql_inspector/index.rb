module MysqlInspector
  class Index < Struct.new(:name, :column_names, :unique)

    def =~(matcher)
      name =~ matcher || column_names.any? { |c| c =~ matcher }
    end

  end
end
