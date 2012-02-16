require 'helper'

describe MysqlInspector::Dump do

  subject do
    MysqlInspector::Dump.new(tmpdir, database_name)
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
      create_mysql_database(schema_a)
      subject.write!
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
  end

  describe "when written but a database does not exist" do
    it "fails" do
      proc {
        subject.write!
      }.must_raise MysqlInspector::Dump::WriteError
    end
  end
end
