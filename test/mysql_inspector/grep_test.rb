require 'helper'

describe MysqlInspector::Grep do

  let(:schema) do
    <<-STR
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `primary` (`id`),
        KEY `name` (`first_name`,`last_name`),
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  let(:dump) {
    dump = MiniTest::Mock.new
    dump.expect(:tables, [table])
    dump
  }

  let(:table) { MysqlInspector::Table.new("test", schema) }

  let(:matchers) { [] }

  subject do
    MysqlInspector::Grep.new(dump, matchers)
  end

  before do
    subject.execute
  end

  describe "with one matcher" do

    let(:matchers) { [/^first_name$/] }

    it "finds the column" do
      subject.columns.size.must_equal 1
      subject.columns.first.name.must_equal "first_name"
    end

    it "finds the index" do
      subject.indices.size.must_equal 1
      subject.indices.first.name.must_equal "name"
    end

    it "finds the constraint" do
      subject.constraints.size.must_equal 1
      subject.constraints.first.name.must_equal "belongs_to_user"
    end
  end

  describe "with multiple matchers (matching with AND)" do

    let(:matchers) { [/^first_name$/, /^last_name$/] }

    it "finds no column" do
      subject.columns.size.must_equal 0
    end

    it "finds the index" do
      subject.indices.size.must_equal 1
      subject.indices.first.name.must_equal "name"
    end

    it "finds the constraint" do
      subject.constraints.size.must_equal 1
      subject.constraints.first.name.must_equal "belongs_to_user"
    end
  end
end
