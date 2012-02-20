describe "mysql-inspector load" do

  describe "parsing arguments" do

    subject { parse_command(MysqlInspector::CLI::LoadCommand, args) }
    let(:args) { [] }

    specify "it fails when you don't specify a database" do
      stderr.must_equal "Usage: mysql-inspector load DATABASE [VERSION]"
      stdout.must_equal ""
    end

    specify "it loads from current" do
      args.concat ["my_database"]
      subject.ivar(:database).must_equal "my_database"
      subject.ivar(:version).must_equal "current"
    end

    specify "it loads another version" do
      args.concat ["my_database", "other"]
      subject.ivar(:database).must_equal "my_database"
      subject.ivar(:version).must_equal "other"
    end
  end

  describe "running" do
    subject { inspect_database "load #{database_name}" }
    specify do
      create_mysql_database schema_b
      inspect_database "write #{database_name}"
      create_mysql_database ideas_schema
      cli_access.table_names.size.must_equal 1

      it "outputs nothing"
      stdout.must_equal ""
      stderr.must_equal ""
      status.must_equal 0

      it "creates all tables"
      cli_access.table_names.size.must_equal 3
    end
  end
end
