require 'helper'

describe "mysql-inspector grep" do

  before do
    create_mysql_database users_and_things_schema
  end

  subject { inspect_database "grep THING" }

  describe "when no dump exists" do
    it "tells you" do
      stdout.must_equal ""
      stderr.must_equal %(Cannot grep because dump "current" does not exist)
      status.must_equal 1
    end
  end

end
