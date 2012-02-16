require 'minitest/autorun'
require 'minitest/mock'
require 'open3'
require 'ostruct'

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
  # schema - String schema to create.
  #
  # Returns nothing.
  def create_mysql_database(schema)
    @mysql_database = true
    MysqlUtils.create_mysql_database(database_name, schema)
  end

  before do
    @tmpdirs = {}
    @mysql_database = nil
  end

  after do
    @tmpdirs.values.each { |dir| FileUtils.rm_rf dir }
    MysqlUtils.drop_mysql_database(database_name) if @mysql_database
  end
end

class MysqlInspectorBinarySpec < MysqlInspectorSpec

  register_spec_type(self) { |desc| desc =~ /mysql-inspector/ }

  def mysql_inspector(args)
    stdout, stderr, status = Open3.capture3("mysql-inspector #{args}")
    OpenStruct.new(:stdout => stdout, :stderr => stderr, :status => status.exitstatus)
  end

  def inspect_database(args)
    mysql_inspector "--out #{tmpdir} #{args}"
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
