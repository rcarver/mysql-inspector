require 'helper'

describe MysqlInspector::Diff do

  let(:current_dump) do
    mock = MiniTest::Mock.new
    mock.expect :tables, [
      MysqlInspector::Table.new(ideas_schema),
      MysqlInspector::Table.new(colors_schema),
      MysqlInspector::Table.new(things_schema_1)
    ]
    mock
  end

  let(:target_dump) do
    mock = MiniTest::Mock.new
    mock.expect :tables, [
      MysqlInspector::Table.new(users_schema),
      MysqlInspector::Table.new(ideas_schema),
      MysqlInspector::Table.new(things_schema_2)
    ]
    mock
  end

  subject do
    MysqlInspector::Diff.new(current_dump, target_dump)
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
      names(table.missing_indices).must_equal ["color"]

      it "finds the constraints that are added"
      names(table.added_constraints).must_equal ["belongs_to_user"]

      it "finds the constraints that are missing"
      names(table.missing_constraints).must_equal ["belongs_to_color"]
    end
  end

end
