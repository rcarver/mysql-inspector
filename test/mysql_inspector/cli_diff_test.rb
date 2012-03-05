require 'helper'

describe "mysql-inspector diff" do

  describe "parsing arguments" do

    subject { parse_command(MysqlInspector::CLI::DiffCommand, args) }
    let(:args) { [] }

    specify "it compares current to target" do
      subject.ivar(:version1).must_equal "current"
      subject.ivar(:version2).must_equal "target"
    end

    specify "it compares current to something else" do
      args << "other"
      subject.ivar(:version1).must_equal "current"
      subject.ivar(:version2).must_equal "other"
    end

    specify "it compares two arbitrary versions" do
      args << "other1"
      args << "other2"
      subject.ivar(:version1).must_equal "other1"
      subject.ivar(:version2).must_equal "other2"
    end
  end

  describe "running" do

    subject { inspect_database "diff" }

    before do
      create_mysql_database schema_a
      inspect_database "write #{database_name} current"
      create_mysql_database schema_b
      inspect_database "write #{database_name} target"
    end

    specify do
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
