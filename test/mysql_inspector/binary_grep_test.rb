require 'helper'

describe "mysql-inspector grep" do

  before do
    create_mysql_database [users_schema, things_schema] * ";"
  end

  describe "in general" do

    subject { inspect_database "grep name" }

    describe "when no dump exists" do
      it "tells you" do
        stderr.must_equal %(Dump "current" does not exist)
        stdout.must_equal ""
        status.must_equal 1
      end
    end
  end

  describe "when a dump exists" do
    before do
      inspect_database "write #{database_name}"
    end

    describe "searching for a single term" do

      subject { inspect_database "grep name" }

      it "finds stuff" do
        stderr.must_equal ""
        stdout.must_equal <<-EOL.unindented
          mysql_inspector_test@current

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
    end

    describe "anchoring the seach term" do

      subject { inspect_database "grep '^name'" }

      it "finds stuff" do
        stderr.must_equal ""
        stdout.must_equal <<-EOL.unindented
          mysql_inspector_test@current

          grep /^name/

          things
          COL    `name` varchar(255) NOT NULL DEFAULT 'toy'
          IDX    KEY `name` (`first_name`,`last_name`)

          users
          IDX    KEY `name` (`first_name`,`last_name`)

        EOL
        status.must_equal 0
      end
    end

    describe "searching for multiple terms" do

      subject { inspect_database "grep name first" }

      it "finds stuff" do
        stderr.must_equal ""
        stdout.must_equal <<-EOL.unindented
          mysql_inspector_test@current

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
end
