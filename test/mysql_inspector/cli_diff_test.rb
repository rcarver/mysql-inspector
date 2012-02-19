require 'helper'

describe "mysql-inspector diff" do

  describe "in general" do

    before do
      create_mysql_database schema_a
    end

    subject { inspect_database "diff" }

    describe "when no current dump exists" do
      it "tells you" do
        stderr.must_equal %(Dump "current" does not exist)
        stdout.must_equal ""
        status.must_equal 1
      end
    end

    describe "when no target dump exists" do
      it "tells you" do
        inspect_database "write #{database_name}"
        stderr.must_equal %(Dump "target" does not exist)
        stdout.must_equal ""
        status.must_equal 1
      end
    end
  end

  describe "when two dumps exist to compare" do

    before do
      create_mysql_database schema_a
      inspect_database "write #{database_name} current"
      create_mysql_database schema_b
      inspect_database "write #{database_name} target"
    end

    subject { inspect_database "diff" }

    it "shows the differences" do
      stderr.must_equal ""
      stdout.must_equal <<-EOL.unindented
        diff mysql_inspector_test@current mysql_inspector_test@target

        - colors
        = things
          COL    - `color` varchar(255) NOT NULL
                 + `first_name` varchar(255) NOT NULL
                 + `last_name` varchar(255) NOT NULL
          IDX    - KEY `color` (`color`)
                 + KEY `name` (`first_name`,`last_name`)
          CST    - CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
                 + CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
        + users

      EOL
      status.must_equal 0
    end
  end
end
