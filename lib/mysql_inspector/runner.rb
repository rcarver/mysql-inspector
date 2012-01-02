module MysqlInspector
  module Runner

    def self.mysql_user=(name)
      @mysql_user = name
    end

    def self.mysql_user
      @mysql_user ||= "root"
    end

    def self.mysqldump(*args)
      all_args = ["-u #{mysql_user}"] + args
      Command.new(mysqldump_path, *all_args).run!
    end

  protected
  
    def self.mysqldump_path
      @mysqldump_path ||= begin
        path = `which mysqldump`.chomp
        raise RuntimeError, "mysqldump was not in your path" if path.empty?
        path
      end
    end

    class Command

      def initialize(path, *args)
        @path = path
        @args = args
      end

      def to_s
        "#{@path} #{@args * " "}"
      end

      def run!
        system to_s
      end
    end

  end
end