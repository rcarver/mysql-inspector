require 'helper_ar'

describe "activerecord config" do

  subject { MysqlInspector::Config.new }

  it "uses Access::AR" do
    subject.access("test").must_be_instance_of MysqlInspector::Access::AR
  end

  it "uses ARDump" do
    subject.create_dump("test").must_be_instance_of MysqlInspector::ARDump
  end

  it "creates AR connections" do
    conn = subject.active_record_connection(database_name)
    conn.select_values("show tables").inspect
  end
end
