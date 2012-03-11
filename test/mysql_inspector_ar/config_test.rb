require 'helper_ar'

describe "activerecord config" do

  subject { MysqlInspector::Config.new }

  it "uses Access::AR" do
    subject.database_name = database_name
    subject.access.must_be_instance_of MysqlInspector::Access::AR
  end

  it "uses ARDump" do
    subject.create_dump("test").must_be_instance_of MysqlInspector::ARDump
  end
end
