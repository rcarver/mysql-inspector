require 'helper_ar'

describe "activerecord migrations" do

  let(:dump) { MysqlInspector::Dump.new(tmpdir) }

  subject do
    MysqlInspector::Migrations.new(tmpdir)
  end

  before do
    run_active_record_migrations!
  end

  describe "when written" do
    before do
      subject.write!(access)
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
      dump.write!(access)
      subject.write!(access)
      create_mysql_database
      dump.load!(access)
      subject.load!(access)
    end
    it "loads migrations" do
      values = ActiveRecord::Base.connection.select_values("select * from schema_migrations")
      values.sort.must_equal ["111", "222"]
    end
  end
end

