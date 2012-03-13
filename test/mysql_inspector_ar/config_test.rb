require 'helper_ar'

describe "activerecord config" do

  it "uses AR::Access" do
    config.database_name = database_name
    config.access.must_be_instance_of MysqlInspector::AR::Access
  end

  it "uses AR::Dump" do
    config.create_dump("test").must_be_instance_of MysqlInspector::AR::Dump
  end
end
