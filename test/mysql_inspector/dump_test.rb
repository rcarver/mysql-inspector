require 'helper'

describe MysqlInspector::Dump do

  let(:extras) { [] }

  subject do
    MysqlInspector::Dump.new(tmpdir, *extras)
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

  describe "extras" do

    let(:extra) { MiniTest::Mock.new }

    before do
      create_mysql_database
    end
    after do
      extra.verify
    end

    it "writes extras" do
      extra.expect :write!, nil, [access]
      extras << extra
      subject.write!(access)
    end
    it "loads extras" do
      extra = MiniTest::Mock.new
      extra.expect :load!, nil, [access]
      extras << extra
      subject.load!(access)
    end
  end
end
