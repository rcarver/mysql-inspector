require 'helper'

describe MysqlInspector::Config do

  subject { MysqlInspector::Config.new }

  it "uses Access" do
    subject.database_name = "test"
    subject.access.must_be_instance_of MysqlInspector::Access
  end

  it "uses Dump" do
    subject.create_dump("test").must_be_instance_of MysqlInspector::Dump
  end
end

