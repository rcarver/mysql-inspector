require 'helper_ar'

describe "dump activerecord migrations" do

  before do
    run_active_record_migrations!
  end

  subject do
    MysqlInspector::AR::Dump.new(tmpdir)
  end

  describe "when written" do
    before do
      subject.write!(ar_access)
    end
    it "has tables" do
      subject.tables.size.must_equal 3
    end
    it "writes tables to disk" do
      Dir[File.join(tmpdir, "*.table")].size.must_equal 3
    end
    it "has migrations" do
      subject.migrations.size.must_equal 2
    end
    it "writes migrations to disk" do
      file = File.join(tmpdir, "schema_migrations.tsv")
      File.exist?(file).must_equal true
      migrations = File.read(file)
      migrations.must_equal <<-EOL.unindented
        111
        222
      EOL
    end
  end

  describe "when loaded" do
    before do
      subject.write!(ar_access)
      create_mysql_database
      subject.load!(ar_access)
    end
    it "recreates all of the tables" do
      ar_access.table_names.sort.must_equal ["schema_migrations", "things", "users"]
    end
    it "loads migrations" do
      values = ActiveRecord::Base.connection.select_values("select * from schema_migrations")
      values.sort.must_equal ["111", "222"]
    end
  end
end
