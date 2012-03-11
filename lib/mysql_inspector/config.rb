module MysqlInspector
  class Config

    def initialize
      @mysql_user = "root"
      @mysql_password = nil
      @mysql_binary = "mysql"
      @dir = File.expand_path(Dir.pwd)
    end

    #
    # Config
    #

    attr_accessor :mysql_user
    attr_accessor :mysql_password
    attr_accessor :mysql_binary

    attr_accessor :database_name
    attr_accessor :dir

    def rails!
      @rails = true
      self.dir = File.join(Rails.root, "db")
    end

    def rails?
      !!@rails
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
        if rails? && database_name
          config = ActiveRecord::Base.configurations[database_name]
          config or raise MysqlInspector::Access::Error, "The database configuration #{database_name.inspect} does not exist"
          ActiveRecord::Base.establish_connection(config)
        end
        MysqlInspector::AR::Access.new(ActiveRecord::Base.connection)
      else
        MysqlInspector::Access.new(database_name, mysql_user, mysql_password, mysql_binary)
      end
    end
  end
end
