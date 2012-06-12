require 'helper_ar'

describe "dump and load activerecord" do

  subject { MysqlInspector::Dump.new(tmpdir) }

  describe "when written" do
    before do
      create_mysql_database(schema_b)
      subject.write!(access)
    end
    it "has tables" do
      subject.tables.size.must_equal 3
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
end
