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

  protected

    def disable_foreign_keys
      "SET foreign_key_checks = 0"
    end

    def enable_foreign_keys
      "SET foreign_key_checks = 1"
    end

  end
end
