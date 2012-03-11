module MysqlInspector
  class Config

    #
    # Config
    #

    def mysql_user=(user)
      @mysql_user = user
    end

    def mysql_user
      @mysql_user ||= "root"
    end

    def mysql_password=(password)
      @mysql_password = password
    end

    def mysql_password
      @mysql_password
    end

    def database_name=(name)
      @database_name = name
    end

    def database_name
      @database_name or raise "No database has been configured"
    end

    def dir=(dir)
      @dir = dir
    end

    def dir
      @dir ||= File.expand_path(Dir.pwd)
    end

    def mysql_binary=(path)
      @mysql_binary = path
    end

    def mysql_binary
      @mysql_binary ||= begin
        path = `which mysql`.chomp
        raise RuntimeError, "mysql is not in your $PATH" if path.empty?
        path
      end
    end

    #
    # API
    #

    def create_dump(version)
      raise [dir, version].inspect if dir.nil? or version.nil?
      file = File.join(dir, version)
      if active_record?
        AR::Dump.new(file)
      else
        Dump.new(file)
      end
    end

    def write_dump(version)
      create_dump(version).write!(access)
    end

    def load_dump(version)
      create_dump(version).load!(access)
    end

    #
    # Impl
    #

    def active_record?
      defined?(ActiveRecord)
    end

    def access
      if active_record?
        MysqlInspector::AR::Access.new(ActiveRecord::Base.connection)
      else
        MysqlInspector::Access.new(database_name, mysql_user, mysql_password, mysql_binary)
      end
    end
  end
end
