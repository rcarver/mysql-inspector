require 'helpers/string_unindented'

# Sample table schemas used for testing.
module MysqlSchemas

  # A sample starting database.
  def schema_a
    [ideas_schema, colors_schema, things_schema_1].join(";\n")
  end

  # A sample changed database.
  def schema_b
    [users_schema, ideas_schema, things_schema_2].join(";\n")
  end

  def colors_schema
    <<-STR.unindented
      CREATE TABLE `colors` (
        `name` varchar(255) NOT NULL,
        UNIQUE KEY `colors_primary` (`name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  def ideas_schema
    <<-STR.unindented
      CREATE TABLE `ideas` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `description` text NOT NULL,
        PRIMARY KEY (`id`),
        KEY `name` (`name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  def users_schema
    <<-STR.unindented
      CREATE TABLE `users` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `first_name` varchar(255) NOT NULL,
        `last_name` varchar(255) NOT NULL,
        UNIQUE KEY `users_primary` (`id`),
        KEY `name` (`first_name`,`last_name`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  def things_schema_1
    <<-STR.unindented
      CREATE TABLE `things` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL DEFAULT 'toy',
        `weight` int(11) DEFAULT NULL,
        `color` varchar(255) NOT NULL,
        UNIQUE KEY `things_primary` (`id`),
        KEY `color` (`color`),
        CONSTRAINT `belongs_to_color` FOREIGN KEY (`color`) REFERENCES `colors` (`name`) ON DELETE NO ACTION ON UPDATE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8
    STR
  end

  def things_schema_2
    <<-STR.unindented
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

  def things_schema
    things_schema_2
  end
end

