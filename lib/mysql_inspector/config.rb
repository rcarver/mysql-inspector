module MysqlInspector
  class Config

    def initialize
      @mysql_user = "root"
      @mysql_password = nil
      @mysql_binary = "mysql"
      @dir = File.expand_path(Dir.pwd)
      @migrations = false
      @rails = false
    end

    #
    # Config
    #

    attr_accessor :mysql_user
    attr_accessor :mysql_password
    attr_accessor :mysql_binary

    attr_accessor :database_name
    attr_accessor :dir

    attr_accessor :migrations
    attr_accessor :rails

    def rails!
      @rails = true
      @migrations = true
      @dir = "db"
    end

    #
    # API
    #

    def create_dump(version)
      raise ["Missing dir or version", dir, version].inspect if dir.nil? or version.nil?
      file = File.join(dir, version)
      extras = []
      extras << Migrations.new(file) if migrations
      Dump.new(file, *extras)
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

    def load_rails_env!
      if rails
        if !defined?(Rails)
          rails_env = File.expand_path('config/environment',  Dir.pwd)
          if File.exist?(rails_env + ".rb")
            require rails_env
          end
        end
        if database_name
          config = ActiveRecord::Base.configurations[database_name]
          config or raise MysqlInspector::Access::Error, "The database configuration #{database_name.inspect} does not exist"
          ActiveRecord::Base.establish_connection(config)
        end
      end
    end

    def access
      load_rails_env!
      if migrations
        MysqlInspector::AR::Access.new(ActiveRecord::Base.connection)
      else
        MysqlInspector::Access.new(database_name, mysql_user, mysql_password, mysql_binary)
      end
    end
  end
end
