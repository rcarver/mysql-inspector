require 'helper'

describe MysqlInspector::Dump do

  let(:schema) do
    <<-STR
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `users_primary` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `things_primary` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  let(:dir) { "/tmp/mysql_inspector_test_#{Time.now.to_f}" }

  subject do
    MysqlInspector::Dump.new(dir, database_name)
  end

  after do
    FileUtils.rm_rf dir
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
      create_mysql_database(schema)
      subject.write!
    end
    after do
      drop_mysql_database
    end
    it "does exist" do
      subject.exists?.must_equal true
    end
    it "has a timestamp" do
      subject.timestamp.to_i.must_equal Time.now.utc.to_i
    end
    it "has tables" do
      subject.tables.size.must_equal 2
    end
  end
end
