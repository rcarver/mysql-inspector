require 'helper_ar'

describe "activerecord config" do

  subject { MysqlInspector::Config.new }

  it "uses AR::Access" do
    subject.database_name = database_name
    subject.access.must_be_instance_of MysqlInspector::AR::Access
  end

  it "uses AR::Dump" do
    subject.create_dump("test").must_be_instance_of MysqlInspector::AR::Dump
  end
end
