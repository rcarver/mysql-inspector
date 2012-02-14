require 'helper'

describe "mysql-inspector -v" do

  subject { mysql_inspector "-v" }

  it "shows the version" do
    stdout.must_equal MysqlInspector::VERSION
    stderr.must_equal ""
    status.must_equal 0
  end
end

describe "mysql-inspector -h" do

  subject { mysql_inspector "-h" }

  it "shows the help" do
    stdout.must_equal ""
    stderr.must_equal <<-EOL.unindented
      Usage: mysql-inspector [options] command [command args]

      Options

              --db DATABASE                Operate on DATABASE
              --on VERSION                 Perform the given action(s) with the VERSION (current or target).
              --out DIR                    Where to store schemas. Defaults to '.'
          -h, --help                       What you're looking at
          -v, --version                    Show the version of mysql-inspector

      Commands

        diff
        grep pattern [pattern]

    EOL
    status.must_equal 1
  end
end

