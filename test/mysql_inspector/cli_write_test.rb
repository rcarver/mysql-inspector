require 'helper'

describe "mysql-inspector write" do

  describe "parsing arguments" do

    subject { parse_command(MysqlInspector::CLI::WriteCommand, args) }
    let(:args) { [] }

    specify "it fails when you don't specify a database" do
      stderr.must_equal "Usage: mysql-inspector write DATABASE [VERSION]"
      stdout.must_equal ""
    end

    specify "it writes to current" do
      args.concat ["my_database"]
      subject.ivar(:database).must_equal "my_database"
      subject.ivar(:version).must_equal "current"
    end

    specify "it writes to another version" do
      args.concat ["my_database", "other"]
      subject.ivar(:database).must_equal "my_database"
      subject.ivar(:version).must_equal "other"
    end
  end

  describe "running" do

    subject { run_command(MysqlInspector::CLI::WriteCommand, args) }
    let(:args) { [database_name] }

    let(:dirname) { "#{tmpdir}/current" }

    specify "when the database does not exist" do
      it "fails"
      stdout.must_equal ""
      stderr.must_equal "The database mysql_inspector_test does not exist"
      status.must_equal 1

      it "does not create a directory"
      File.directory?(dirname).must_equal false
    end

    specify "when the database exists" do
      create_mysql_database schema_a

      it "succeeds"
      stdout.must_equal ""
      stderr.must_equal ""
      status.must_equal 0

      it "creates a directory and files"
      File.directory?(dirname).must_equal true
      Dir.glob(dirname + "/*.table").size.must_equal 3
    end
  end
end
