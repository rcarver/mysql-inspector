require 'helper'
require 'active_record'

class MysqlInspectorActiveRecordpec < MysqlInspectorSpec

  register_spec_type(self) { |desc| desc =~ /activerecord/ }

  before do
    create_mysql_database
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection(
        :adapter => :mysql2,
        :database => database_name,
        :username => "root",
        :password => nil
      )
    end
  end

  def run_active_record_migrations!
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate(["test/fixtures/migrate"])
  end
end
