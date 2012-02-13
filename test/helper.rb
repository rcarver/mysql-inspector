require 'minitest/autorun'
require 'mysql_inspector'

require 'tempfile'

def mysql_command
  @mysql_command ||= begin
    path = `which mysql`.chomp
    raise "mysql is not in your PATH" if path.empty?
    "#{path} -uroot"
  end
end

def syscall(command)
  raise "FAILED: #{command.inspect}" unless system(command)
end

def database_name
  "mysql_inspector"
end

def create_mysql_database(schema)
  drop_mysql_database
  syscall "echo 'CREATE DATABASE #{database_name}' | #{mysql_command}"
  Tempfile.open('schema') do |file|
    file.puts(schema)
    file.flush
    syscall "cat #{file.path} | #{mysql_command} #{database_name}"
  end
end

def drop_mysql_database
  syscall "echo 'DROP DATABASE IF EXISTS #{database_name}' | #{mysql_command}"
end
