require 'minitest/autorun'
require 'mysql_inspector'

require 'tempfile'
require 'timecop'

class String
  # Strip left indentation from a string. Call this on a HEREDOC
  # string to unindent it.
  def unindented
    lines = self.split("\n")
    indent_level = (lines[0][/^(\s*)/, 1] || "").size
    lines.map { |line|
      line.sub(/^\s{#{indent_level}}/, '')
    }.join("\n") + "\n"
  end
end

class SystemCall
  def initialize(command)
    @stdout, @stderr, status = Open3.capture3(command)
    @status = status.exitstatus
  end
  attr_reader :stdout, :stderr, :status
end

module Schemas
  # A database with two related tables - users, and things.
  def users_and_things_schema
    <<-STR.unindented
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `users_primary` (`id`),
        KEY `name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      #{things_schema}
    STR
  end
  # The things table from users_and_things_schema
  def things_schema
    <<-STR.unindented
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `name` (`first_name`,`last_name`),
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end
end

class MysqlInspectorSpec < MiniTest::Spec
  include Schemas

  def it msg
    raise "A block must not be passed to the example-level +it+" if block_given?
    @__current_msg = "it #{msg}"
  end

  def message msg = nil, ending = ".", &default
    super(msg || @__current_msg, ending, &default)
  end

  register_spec_type(self) { |desc| true }

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
    result = SystemCall.new(command)
    raise "FAILED:\n\nstdout:\n#{result.stdout}\n\nstderr:\n#{result.stderr}" unless result.status == 0
  end

  def drop_mysql_database
    syscall "echo 'DROP DATABASE IF EXISTS #{database_name}' | #{mysql_command}"
  end
end

class MysqlInspectorBinarySpec < MysqlInspectorSpec

  register_spec_type(self) { |desc| desc =~ /mysql-inspector/ }

  def mysql_inspector(args)
    SystemCall.new "mysql-inspector #{args}"
  end

  def inspect_database(args)
    mysql_inspector "--db #{database_name} --out #{tmpdir} #{args}"
  end

  def stdout
    subject.stdout.chomp
  end

  def stderr
    subject.stderr.chomp
  end

  def status
    subject.status
  end
end
