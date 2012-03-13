require 'helper'

describe MysqlInspector::Config do

  it "uses Access" do
    config.database_name = "test"
    config.access.must_be_instance_of MysqlInspector::Access
  end

  it "uses Dump" do
    config.create_dump("test").must_be_instance_of MysqlInspector::Dump
  end
end

