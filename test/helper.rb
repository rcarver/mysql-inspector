require 'minitest/autorun'
require 'mysql_inspector'

require 'tempfile'

class MysqlInspectorSpec < MiniTest::Spec

  # Create a temporary directory. This directory will exist for the life of
  # the spec.
  #
  # Returns a String.
  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  # Get the name of the test database.
  #
  # Returns a String.
  def database_name
    "mysql_inspector_test"
  end

  # Create a test mysql database. The database will exist for the life
  # of the spec.
  #
  # schema - String schema to create.
  #
  # Returns nothing.
  def create_mysql_database(schema)
    @mysql_database = true
    drop_mysql_database
    syscall "echo 'CREATE DATABASE #{database_name}' | #{mysql_command}"
    Tempfile.open('schema') do |file|
      file.puts(schema)
      file.flush
      syscall "cat #{file.path} | #{mysql_command} #{database_name}"
    end
  end

  register_spec_type /.*/, self

  before do
    @tmpdir = nil
    @mysql_database = nil
  end

  after do
    FileUtils.rm_rf @tmpdir if @tmpdir
    drop_mysql_database if @mysql_database
  end

 protected

  def self.mysql_command
    @mysql_command ||= begin
      path = `which mysql`.chomp
      raise "mysql is not in your PATH" if path.empty?
      "#{path} -uroot"
    end
  end

  def mysql_command
    self.class.mysql_command
  end

  def syscall(command)
    raise "FAILED: #{command.inspect}" unless system(command)
  end

  def drop_mysql_database
    syscall "echo 'DROP DATABASE IF EXISTS #{database_name}' | #{mysql_command}"
  end
end

