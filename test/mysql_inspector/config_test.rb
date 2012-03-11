require 'helper'

describe MysqlInspector::Config do

  subject { MysqlInspector::Config.new }

  it "uses Access::CLI" do
    subject.access("test").must_be_instance_of MysqlInspector::Access::CLI
  end

  it "uses Dump" do
    subject.create_dump("test").must_be_instance_of MysqlInspector::Dump
  end
end

