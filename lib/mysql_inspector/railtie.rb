require 'mysql_inspector'

# Ensure that ActiveRecord has initialized.
require "active_record/railtie"

module MysqlInspector
  class Railtie < Rails::Railtie

    # Store your schema in the MysqlInspector schema format.
    config.active_record.schema_format = :mysql_inspector

    rake_tasks do
      load "mysql_inspector/railties/databases.rake"
    end
  end
end

