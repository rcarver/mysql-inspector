require 'helper'

describe MysqlInspector::Table do

  subject do
    MysqlInspector::Table.new(things_schema)
  end

  it "knows the table name" do
    subject.table_name.must_equal "things"
  end

  it "extracts all of the columns" do
    subject.columns.size.must_equal 5
  end

  it "describes each column" do
    subject.columns[0].must_equal MysqlInspector::Column.new("first_name", "varchar(255)", false, nil, false)
    subject.columns[1].must_equal MysqlInspector::Column.new("id", "int(11)", false, nil, true)
    subject.columns[2].must_equal MysqlInspector::Column.new("last_name", "varchar(255)", false, nil, false)
    subject.columns[3].must_equal MysqlInspector::Column.new("name", "varchar(255)", false, "'toy'", false)
    subject.columns[4].must_equal MysqlInspector::Column.new("weight", "int(11)", true, nil, false)
  end

  it "extracts all of the indices" do
    subject.indices.size.must_equal 2
  end

  it "describes each index" do
    subject.indices[0].must_equal MysqlInspector::Index.new("name", ["first_name", "last_name"], false)
    subject.indices[1].must_equal MysqlInspector::Index.new("things_primary", ["id"], true)
  end

  it "extracts all of the constraints" do
    subject.constraints.size.must_equal 1
  end

  it "describes each constraint" do
    subject.constraints[0].must_equal MysqlInspector::Constraint.new("belongs_to_user", ["first_name", "last_name"], "users", ["first_name", "last_name"], "CASCADE", "NO ACTION")
  end

  it "describes the options" do
    subject.options.must_equal "ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end

  it "excludes the AUTO_INCREMENT option" do
    table = MysqlInspector::Table.new(") ENGINE=InnoDB AUTO_INCREMENT=122 CHARSET=utf8;")
    table.options.must_equal "ENGINE=InnoDB CHARSET=utf8"
  end

  it "generates a simplified schema" do
    subject.to_s.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `things`

      `first_name` varchar(255) NOT NULL
      `id` int(11) NOT NULL AUTO_INCREMENT
      `last_name` varchar(255) NOT NULL
      `name` varchar(255) NOT NULL DEFAULT 'toy'
      `weight` int(11) NULL

      KEY `name` (`first_name`,`last_name`)
      UNIQUE KEY `things_primary` (`id`)

      CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE

      ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end

  it "may be instantiated with a simplified schema" do
    MysqlInspector::Table.new(subject.to_s).must_equal subject
  end

  it "generates a real schema" do
    subject.to_sql.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `things` (
        `first_name` varchar(255) NOT NULL,
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `last_name` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        KEY `name` (`first_name`,`last_name`),
        UNIQUE KEY `things_primary` (`id`),
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end
end
