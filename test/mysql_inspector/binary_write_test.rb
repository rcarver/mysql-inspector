require 'helper'

describe "mysql-inspector write" do

  describe "when you don't specify a database" do

    subject { inspect_database "write" }
    it "fails" do
      stdout.must_equal ""
      stderr.must_equal "Usage: mysql-inspector write DATABASE [VERSION]"
      status.must_equal 1
    end
  end

  describe "by default" do

    subject { inspect_database "write #{database_name}" }

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
      Dir.glob(dirname + "/*.sql").size.must_equal 3
    end
  end

  describe "writing another version" do

    subject { inspect_database "write #{database_name} target" }

    let(:dirname) { "#{tmpdir}/target" }

    it "creates a directory and files" do
      create_mysql_database schema_a

      it "succeeds"
      stdout.must_equal ""
      stderr.must_equal ""
      status.must_equal 0

      it "creates a directory and files"
      File.directory?(dirname).must_equal true
    end
  end
end
