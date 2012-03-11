require 'helper'

describe MysqlInspector::Dump do

  subject do
    MysqlInspector::Dump.new(tmpdir)
  end

  describe "before written" do
    it "does not exist" do
      subject.exists?.must_equal false
    end
    it "has no timestamp" do
      subject.timestamp.must_equal nil
    end
    it "has no tables" do
      subject.tables.size.must_equal 0
    end
  end

  describe "when written" do
    before do
      create_mysql_database(schema_b)
      subject.write!(access)
    end
    it "does exist" do
      subject.must_be :exists?
    end
    it "has a timestamp" do
      subject.timestamp.to_i.must_equal Time.now.utc.to_i
    end
    it "has tables" do
      subject.tables.size.must_equal 3
    end
    it "writes simple schemas to disk" do
      file = File.join(tmpdir, "things.table")
      File.exist?(file).must_equal true
      schema = File.read(file)
      schema.must_equal MysqlInspector::Table.new(things_schema).to_simple_schema
    end
  end

  describe "when loaded" do
    before do
      create_mysql_database(schema_b)
      subject.write!(access)
      create_mysql_database(ideas_schema)
    end
    it "recreates all of the tables, even ones that already exist" do
      access.table_names.must_equal ["ideas"]
      subject.load!(access)
      access.table_names.sort.must_equal ["ideas", "things", "users"]
    end
  end

  describe "when written but a database does not exist" do
    it "fails" do
      proc { subject.write!(access) }.must_raise MysqlInspector::Access::Error
    end
  end
end
