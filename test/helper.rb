require 'minitest/autorun'
require 'minitest/mock'
require 'open3'
require 'ostruct'
require 'stringio'

require 'mysql_inspector'

require 'helpers/mysql_utils'
require 'helpers/mysql_schemas'
require 'helpers/string_unindented'

class MysqlInspectorSpec < MiniTest::Spec
  include MysqlSchemas

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
  # id - Identifier of the tmpdir (default: the default identifier).
  #
  # Returns a String.
  def tmpdir(id=:default)
    @tmpdirs[id] ||= Dir.mktmpdir
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
  # schema - String schema to create (default: no schema).
  #
  # Returns nothing.
  def create_mysql_database(schema="")
    @mysql_database = true
    MysqlUtils.create_mysql_database(database_name, schema)
  end

  # Drop the test mysql database.
  #
  # Returns nothing.
  def drop_mysql_database
    MysqlUtils.drop_mysql_database(database_name)
  end

  # Get access to the mysql database via the CLI interface.
  #
  # Returns a MysqlInspector:Access::CLI.
  def cli_access
    MysqlInspector::Access::CLI.new(database_name, "root", nil, "mysql")
  end

  before do
    @tmpdirs = {}
    @mysql_database = nil
  end

  after do
    @tmpdirs.values.each { |dir| FileUtils.rm_rf dir }
    drop_mysql_database if @mysql_database
  end
end

class MysqlInspectorCliSpec < MysqlInspectorSpec

  register_spec_type(self) { |desc| desc =~ /mysql-inspector/ }

  let(:config) { MysqlInspector::Config.new }

  before do
    config.dir = tmpdir
  end

  def parse_command(klass, argv)
    command = klass.new(config, StringIO.new, StringIO.new)
    command.parse!(argv)
    command
  end

  def run_command(klass, argv)
    command = klass.new(config, StringIO.new, StringIO.new)
    command.parse!(argv)
    command.run!
    command
  end

  def mysql_inspector(args)
    cli = MysqlInspector::CLI.new(config, StringIO.new, StringIO.new)
    argv = args.split(/\s+/).map { |x| x.gsub(/'/, '') }
    cli.run!(argv)
    cli
  end

  def inspect_database(args)
    mysql_inspector args
  end

  def stdout
    subject.stdout.string.chomp
  end

  def stderr
    subject.stderr.string.chomp
  end

  def status
    subject.status
  end
end
