module MysqlInspector
  class Config

    def mysql_user=(user)
      @mysql_user = user
    end

    def mysql_user
      @mysql_user ||= "root"
    end

    def mysql_password(password)
      @mysql_password = password
    end

    def mysql_password
      @mysql_password
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

    def mysql_command
      [mysql_binary, "-u#{mysql_user}", mysql_password ? "-p#{mysql_password}" : nil].compact * " "
    end

    def dir=(dir)
      @dir = dir
    end

    def dir
      @dir ||= File.expand_path(Dir.pwd)
    end

    def create_dump(version)
      Dump.new(File.join(dir, version))
    end

    def write_dump(version, database_name)
      create_dump(version).write!(database_name)
    end

    def load_dump(version, database_name)
      create_dump(version).load!(database_name)
    end

  end
end
