require 'helper'

describe MysqlInspector::Comparison do

  def colors_schema
    <<-STR.unindented
      CREATE TABLE `colors` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `colors_primary` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  def ideas_schema
    <<-STR.unindented
      CREATE TABLE `ideas` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `description` text NOT NULL,
        UNIQUE KEY `ideas_primary` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  def users_schema
    <<-STR.unindented
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        UNIQUE KEY `users_primary` (`id`),
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  def things_schema_1
    <<-STR.unindented
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        `color` varchar(255) NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `weight` (`weight`)
        CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  def things_schema_2
    <<-STR.unindented
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `name` (`first_name`,`last_name`),
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    STR
  end

  let(:current_dump) do
    mock = MiniTest::Mock.new
    mock.expect :tables, [
      MysqlInspector::Table.new(database_name, ideas_schema),
      MysqlInspector::Table.new(database_name, colors_schema),
      MysqlInspector::Table.new(database_name, things_schema_1)
    ]
    mock
  end

  let(:target_dump) do
    mock = MiniTest::Mock.new
    mock.expect :tables, [
      MysqlInspector::Table.new(database_name, users_schema),
      MysqlInspector::Table.new(database_name, ideas_schema),
      MysqlInspector::Table.new(database_name, things_schema_2)
    ]
    mock
  end

  subject do
    MysqlInspector::Comparison.new(current_dump, target_dump)
  end

  before do
    subject.execute
  end

  def table_names(tables)
    tables.map { |t| t.table_name }
  end

  def names(items)
    items.map { |t| t.name }
  end

  specify "the types of tables" do

    it "finds tables that were added"
    table_names(subject.added_tables).must_equal ["users"]

    it "finds tables that are missing"
    table_names(subject.missing_tables).must_equal ["colors"]

    it "finds tables that are equal"
    table_names(subject.equal_tables).must_equal ["ideas"]

    it "finds tables that differ"
    table_names(subject.different_tables).must_equal ["things"]
  end

  describe "a table that differs" do

    let(:table) { subject.different_tables.first }

    specify "the parts of the table" do

      it "finds the columns that are added"
      names(table.added_columns).must_equal ["first_name", "last_name"]

      it "finds the columns that are missing"
      names(table.missing_columns).must_equal ["color"]

      it "finds the indices that are added"
      names(table.added_indices).must_equal ["name"]

      it "finds the indices that are missing"
      names(table.missing_indices).must_equal ["weight"]

      it "finds the constraints that are added"
      names(table.added_constraints).must_equal ["belongs_to_user"]

      it "finds the constraints that are missing"
      names(table.missing_constraints).must_equal ["belongs_to_color"]
    end
  end

end
