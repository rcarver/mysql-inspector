require 'helper'

describe MysqlInspector::Table do

  subject do
    MysqlInspector::Table.new(<<-STR.unindented)
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) DEFAULT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `name` (`first_name`,`last_name`),
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
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
    subject.to_simple_schema.must_equal <<-EOL.unindented.chomp
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
    MysqlInspector::Table.new(subject.to_simple_schema).must_equal subject
  end

  it "formats a simplified schema well even if the table has nothing" do
    schema = <<-EOL.unindented
      CREATE TABLE `things` (
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
    MysqlInspector::Table.new(schema).to_simple_schema.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `things`

      ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end

  it "generates a sql schema" do
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

  it "is a valid sql schema" do
    create_mysql_database join_tables(users_schema, subject.to_sql)
  end
end

describe MysqlInspector::Table, "with PRIMARY KEY" do

  subject do
    MysqlInspector::Table.new(<<-STR.unindented)
      CREATE TABLE `ideas` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `description` text NOT NULL,
        PRIMARY KEY (`id`),
        KEY `name` (`name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  it "describes the index" do
    subject.indices[0].must_equal MysqlInspector::Index.new("PRIMARY KEY", ["id"], true)
  end

  it "generates a sql schema" do
    subject.to_sql.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `ideas` (
        `description` text NOT NULL,
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        PRIMARY KEY (`id`),
        KEY `name` (`name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end

  it "is a valid sql schema" do
    create_mysql_database join_tables(subject.to_sql)
  end
end

describe MysqlInspector::Table, "with two constraints" do

  subject do
    MysqlInspector::Table.new(<<-STR.unindented)
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) DEFAULT NULL,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        `color` varchar(255) NOT NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `color` (`color`),
        KEY `name` (`first_name`,`last_name`),
        CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE,
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`, `last_name`) REFERENCES `users` (`first_name`, `last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  it "knows the table name" do
    subject.table_name.must_equal "things"
  end

  it "extracts all of the columns" do
    subject.columns.size.must_equal 6
  end

  it "describes each column" do
    subject.columns[0].must_equal MysqlInspector::Column.new("color", "varchar(255)", false, nil, false)
    subject.columns[1].must_equal MysqlInspector::Column.new("first_name", "varchar(255)", false, nil, false)
    subject.columns[2].must_equal MysqlInspector::Column.new("id", "int(11)", false, nil, true)
    subject.columns[3].must_equal MysqlInspector::Column.new("last_name", "varchar(255)", false, nil, false)
    subject.columns[4].must_equal MysqlInspector::Column.new("name", "varchar(255)", false, "'toy'", false)
    subject.columns[5].must_equal MysqlInspector::Column.new("weight", "int(11)", true, nil, false)
  end

  it "extracts all of the indices" do
    subject.indices.size.must_equal 3
  end

  it "describes each index" do
    subject.indices[0].must_equal MysqlInspector::Index.new("color", ["color"], false)
    subject.indices[1].must_equal MysqlInspector::Index.new("name", ["first_name", "last_name"], false)
    subject.indices[2].must_equal MysqlInspector::Index.new("things_primary", ["id"], true)
  end

  it "extracts all of the constraints" do
    subject.constraints.size.must_equal 2
  end

  it "describes each constraint" do
    subject.constraints[0].must_equal MysqlInspector::Constraint.new("belongs_to_color", ["color"], "colors", ["name"], "CASCADE", "NO ACTION")
    subject.constraints[1].must_equal MysqlInspector::Constraint.new("belongs_to_user", ["first_name", "last_name"], "users", ["first_name", "last_name"], "CASCADE", "NO ACTION")
  end

  it "generates a simplified schema" do
    subject.to_simple_schema.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `things`

      `color` varchar(255) NOT NULL
      `first_name` varchar(255) NOT NULL
      `id` int(11) NOT NULL AUTO_INCREMENT
      `last_name` varchar(255) NOT NULL
      `name` varchar(255) NOT NULL DEFAULT 'toy'
      `weight` int(11) NULL

      KEY `color` (`color`)
      KEY `name` (`first_name`,`last_name`)
      UNIQUE KEY `things_primary` (`id`)

      CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
      CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE

      ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end

  it "generates a sql schema" do
    subject.to_sql.must_equal <<-EOL.unindented.chomp
      CREATE TABLE `things` (
        `color` varchar(255) NOT NULL,
        `first_name` varchar(255) NOT NULL,
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `last_name` varchar(255) NOT NULL,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) NULL,
        KEY `color` (`color`),
        KEY `name` (`first_name`,`last_name`),
        UNIQUE KEY `things_primary` (`id`),
        CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE,
        CONSTRAINT `belongs_to_user` FOREIGN KEY (`first_name`,`last_name`) REFERENCES `users` (`first_name`,`last_name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    EOL
  end

  it "is a valid sql schema" do
    create_mysql_database join_tables(colors_schema, users_schema, subject.to_sql)
  end
end
