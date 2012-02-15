require 'helper'

describe "mysql-inspector write" do

  subject { inspect_database "write" }

  let(:dirname) { "#{tmpdir}/mysql_#{database_name}_current" }

  describe "when the database does not exist" do
    it "fails" do
      stdout.must_equal ""
      stderr.must_equal "The database #{database_name} does not exist"
      status.must_equal 1
    end
    it "does not create a directory" do
      File.directory?(dirname).must_equal false
    end
  end

  describe "when the database exists" do
    before do
      create_mysql_database users_and_things_schema
    end
    it "succeeds" do
      stdout.must_equal ""
      stderr.must_equal ""
      status.must_equal 0
    end
    it "creates a directory and files" do
      subject.wont_be_nil
      File.directory?(dirname).must_equal true
      Dir.glob(dirname + "/*.sql").size.must_equal 2
    end
  end
end
