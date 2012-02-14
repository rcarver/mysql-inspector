require 'helper'

describe "mysql-inspector grep" do

  before do
    create_mysql_database users_and_things_schema
  end

  subject { inspect_database "grep name first" }

  describe "when no dump exists" do
    it "tells you" do
      stderr.must_equal %(Cannot grep because dump "current" does not exist)
      stdout.must_equal ""
      status.must_equal 1
    end
  end

  describe "when a dump exists" do
    before do
      inspect_database "write"
    end
    it "finds stuff" do
      stderr.must_equal ""
      stdout.must_equal <<-EOL.unindented
        mysql_inspector_test@current

        grep /name/ AND /first/

        Columns
          things
            `first_name` varchar(255) NOT NULL
          users
            `first_name` varchar(255) NOT NULL

        Indices
          things
            KEY `name` (`first_name`,`last_name`)
          users
            KEY `name` (`first_name`,`last_name`)

        Constraints
          things
            CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      EOL
      status.must_equal 0
    end
  end

end
