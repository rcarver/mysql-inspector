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
  result = system(command)
  raise "FAILED: #{command.inspect}" unless result
end

def dbname(name)
  ["mysql_inspector", name] * "_"
end

def create_mysql_database(name, schema)
  drop_mysql_database(name)
  syscall "echo 'CREATE DATABASE #{name}' | #{mysql_command}"
  Tempfile.open('schema') do |file|
    file.puts(schema)
    file.flush
    syscall "cat #{file.path} | #{mysql_command} #{name}"
  end
end

def drop_mysql_database(name)
  syscall "echo 'DROP DATABASE IF EXISTS #{name}' | #{mysql_command}"
end
