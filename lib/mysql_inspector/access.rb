module MysqlInspector
  class Access

    Error = Class.new(StandardError)

    def table_names
      raise NotImplementedError
    end

    def tables
      raise NotImplementedError
    end

    def drop_all_tables
      raise NotImplementedError
    end

    def load(schema)
      raise NotImplementedError
    end

  end
end
