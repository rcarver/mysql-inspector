require 'helper'

describe MysqlInspector::Table do

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

  subject do
    MysqlInspector::Table.new("test", schema)
  end

  it "knows the table name" do
    subject.table_name.must_equal "things"
  end

  it "extracts all of the columns" do
    subject.columns.size.must_equal 5
  end

  it "describes each column" do
    subject.columns[0].must_equal MysqlInspector::Column.new("first_name", "varchar", false, nil)
    subject.columns[1].must_equal MysqlInspector::Column.new("id", "int", false, nil)
    subject.columns[2].must_equal MysqlInspector::Column.new("last_name", "varchar", false, nil)
    subject.columns[3].must_equal MysqlInspector::Column.new("name", "varchar", false, "toy")
    subject.columns[4].must_equal MysqlInspector::Column.new("weight", "int", true, nil)
  end

  it "extracts all of the indices" do
    subject.indices.size.must_equal 2
  end

  it "describes each index" do
    subject.indices[0].must_equal MysqlInspector::Index.new("name", ["first_name", "last_name"], false)
    subject.indices[1].must_equal MysqlInspector::Index.new("primary", ["id"], true)
  end

  it "extracts all of the constraints" do
    subject.constraints.size.must_equal 1
  end

  it "describes each constraint" do
    subject.constraints[0].must_equal MysqlInspector::Constraint.new("belongs_to_user", ["first_name", "last_name"], "users", ["first_name", "last_name"], "CASCADE", "NO ACTION")
  end

end
