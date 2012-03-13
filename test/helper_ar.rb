require 'active_record'
require 'mysql2'
require 'helper'

class MysqlInspectorActiveRecordSpec < MysqlInspectorSpec

  register_spec_type(self) { |desc| desc =~ /activerecord/ }

  before do
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection(
        :adapter => :mysql2,
        :database => database_name,
        :username => "root",
        :password => nil
      )
    end
    create_mysql_database
    config.migrations = true
  end

  # Execute all of the fixture migrations.
  #
  # Returns nothing.
  def run_active_record_migrations!
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate(["test/fixtures/migrate"])
  end

  # Get access to the mysql database.
  #
  # Returns a MysqlInspector:AR::Access.
  def access
    MysqlInspector::AR::Access.new(ActiveRecord::Base.connection)
  end

end
