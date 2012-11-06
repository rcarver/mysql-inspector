require 'helper'

describe "mysql-inspector grep" do

  describe "parsing arguments" do

    subject { parse_command(MysqlInspector::CLI::GrepCommand, args) }
    let(:args) { [] }

    specify "it searches current with one arg" do
      args.concat ["a"]
      subject.ivar(:version).must_equal "current"
      subject.ivar(:matchers).must_equal [/a/]
    end

    specify "it searches current with multiple args" do
      args.concat ["a", "^b"]
      subject.ivar(:version).must_equal "current"
      subject.ivar(:matchers).must_equal [/a/, /^b/]
    end

    specify "it searches another version" do
      skip "not supported. how would the args work?"
    end
  end

  describe "running" do
    before do
      create_mysql_database [users_schema, things_schema] * ";"
      inspect_database "write #{database_name}"
    end

    subject { inspect_database "grep #{matchers * ' '}" }
    let(:matchers) { [] }

    specify "searching for a single term" do
      matchers << "name"

      stderr.must_equal ""
      stdout.must_equal <<-EOL.unindented
        grep /name/

        things
        COL    `first_name` varchar(255) NOT NULL
               `last_name` varchar(255) NOT NULL
               `name` varchar(255) NOT NULL DEFAULT 'toy'
        IDX    KEY `name` (`first_name`,`last_name`)
        CST    CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE

        users
        COL    `first_name` varchar(255) NOT NULL
               `last_name` varchar(255) NOT NULL
        IDX    KEY `name` (`first_name`,`last_name`)

      EOL
      status.must_equal 0
    end

    specify "searching for multiple terms" do
      matchers << "name"
      matchers << "first"

      stderr.must_equal ""
      stdout.must_equal <<-EOL.unindented
        grep /name/ AND /first/

        things
        COL    `first_name` varchar(255) NOT NULL
        IDX    KEY `name` (`first_name`,`last_name`)
        CST    CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE

        users
        COL    `first_name` varchar(255) NOT NULL
        IDX    KEY `name` (`first_name`,`last_name`)

      EOL
      status.must_equal 0
    end
  end
end
