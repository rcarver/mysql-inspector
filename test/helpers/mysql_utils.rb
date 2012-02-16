require 'open3'

module MysqlUtils
  extend self

  def create_mysql_database(database_name, schema)
    drop_mysql_database(database_name)
    syscall "echo 'CREATE DATABASE #{database_name}' | #{mysql_command}"
    Tempfile.open('schema') do |file|
      file.puts(schema)
      file.flush
      syscall "cat #{file.path} | #{mysql_command} #{database_name}"
    end
  end

  def drop_mysql_database(database_name)
    syscall "echo 'DROP DATABASE IF EXISTS #{database_name}' | #{mysql_command}"
  end

 protected

  def mysql_command
    @mysql_command ||= begin
      path = `which mysql`.chomp
      raise "mysql is not in your PATH" if path.empty?
      "#{path} -uroot"
    end
  end

  def syscall(command)
    out, err, status = Open3.capture3(command)
    raise "FAILED:\n\nstdout:\n#{result.stdout}\n\nstderr:\n#{result.stderr}" unless status.exitstatus == 0
  end
end
