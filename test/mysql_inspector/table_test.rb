require 'helper'

describe MysqlInspector::Table do

  subject do
    MysqlInspector::Table.new(things_schema)
  end

  it "knows the table name" do
    subject.table_name.must_equal "things"
  end

  it "extracts all of the columns" do
    subject.columns.size.must_equal 5
  end

  it "describes each column" do
    subject.columns[0].must_equal MysqlInspector::Column.new("first_name", "varchar(255)", false, nil)
    subject.columns[1].must_equal MysqlInspector::Column.new("id", "int(11)", false, nil)
    subject.columns[2].must_equal MysqlInspector::Column.new("last_name", "varchar(255)", false, nil)
    subject.columns[3].must_equal MysqlInspector::Column.new("name", "varchar(255)", false, "toy")
    subject.columns[4].must_equal MysqlInspector::Column.new("weight", "int(11)", true, nil)
  end

  it "extracts all of the indices" do
    subject.indices.size.must_equal 2
  end

  it "describes each index" do
    subject.indices[0].must_equal MysqlInspector::Index.new("name", ["first_name", "last_name"], false)
    subject.indices[1].must_equal MysqlInspector::Index.new("things_primary", ["id"], true)
  end

  it "extracts all of the constraints" do
    subject.constraints.size.must_equal 1
  end

  it "describes each constraint" do
    subject.constraints[0].must_equal MysqlInspector::Constraint.new("belongs_to_user", ["first_name", "last_name"], "users", ["first_name", "last_name"], "CASCADE", "NO ACTION")
  end

end
