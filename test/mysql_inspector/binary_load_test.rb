describe "mysql-inspector load" do

  describe "when you don't specify a database" do

    subject { inspect_database "load" }
    it "fails" do
      stdout.must_equal ""
      stderr.must_equal "Usage: mysql-inspector load DATABASE [VERSION]"
      status.must_equal 1
    end
  end

  describe "by default" do

    subject { inspect_database "load #{database_name}" }

    describe "when the dump does not exist" do
      it "fails" do
        stdout.must_equal ""
        stderr.must_equal "Dump \"current\" does not exist"
        status.must_equal 1
      end
    end

    describe "when the database does not exist" do
      before do
        create_mysql_database ""
        inspect_database "write #{database_name}"
        drop_mysql_database
      end
      it "fails" do
        stdout.must_equal ""
        stderr.must_equal "The database mysql_inspector_test does not exist"
        status.must_equal 1
      end
    end

    describe "when the database and dump exist" do
      before do
        create_mysql_database schema_b
        inspect_database "write #{database_name}"
        create_mysql_database ideas_schema
        cli_access.table_names.size.must_equal 1
      end
      it "succeeds" do
        stdout.must_equal ""
        stderr.must_equal ""
        status.must_equal 0

        it "creates all tables"
        cli_access.table_names.size.must_equal 3
      end
    end
  end
end

