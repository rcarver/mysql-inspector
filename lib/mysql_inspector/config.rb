module MysqlInspector
  class Config

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

    def access(database_name)
      if active_record?
        MysqlInspector::Access::AR.new(database_name, active_record_connection(database_name))
      else
        MysqlInspector::Access::CLI.new(database_name)
      end
    end

    def create_dump(version)
      raise [dir, version].inspect if dir.nil? or version.nil?
      file = File.join(dir, version)
      if active_record?
        ARDump.new(file)
      else
        Dump.new(file)
      end
    end

    def write_dump(version, database_name)
      create_dump(version).write!(access(database_name))
    end

    def load_dump(version, database_name)
      create_dump(version).load!(access(database_name))
    end

    def active_record?
      defined?(ActiveRecord)
    end

    def active_record_connection(database_name)
      @active_record_connection ||= {}
      @active_record_connection[database_name] ||= begin
        klass = Class.new(ActiveRecord::Base)
        klass.establish_connection(
          :adapter => :mysql2,
          :username => mysql_user,
          :password => mysql_password,
          :database => database_name
        )
        klass.connection
      end
    end

  end
end
