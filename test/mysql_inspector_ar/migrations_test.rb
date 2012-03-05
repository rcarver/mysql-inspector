require 'helper_ar'

describe "dump activerecord migrations" do

  before do
    run_active_record_migrations!
  end

  it "works" do
    ActiveRecord::Base.connection.select_values("show tables").sort.must_equal ["schema_migrations", "things", "users"]
  end
end
