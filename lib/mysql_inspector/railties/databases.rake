# This file patches ActiveRecord's databases.rake so that when you dump and
# load databases it goes through mysql-inspector. Patching the existing rake
# tasks is very brittle do the spaghetti nature of the existing code, so if a
# specific task doesn't work please file an issue.

mysql_inspector_db_namespace = namespace :db do

  def mysql_inspector_config(database=nil)
    config = MysqlInspector::Config.new
    config.rails!
    config.database_name = database if database
    config
  end


  #
  # Rewrite public the db:setup task.
  #

  # Totally reset the setup task.
  task(:setup).clear_prerequisites.clear_actions

  # Redefine the setup task to use mysql_inspector.
  task :setup => ['db:create', 'mysql_inspector:load']


  #
  # Rewrite internal the db:_dump task.
  #

  # Totally reset the _dump task.
  task(:_dump).clear_prerequisites.clear_actions

  # Redefine the dump task to always call mysql_inspector:dump.
  task :_dump => "db:mysql_inspector:dump" do
    # Allow this task to be called as many times as required. An example is the
    # migrate:redo task, which calls other two internally that depend on this one.
    mysql_inspector_db_namespace['_dump'].reenable
  end


  #
  # Fix that abort_if_pending_migrations does not properly connect to a database.
  #

  # Reset the prerequisites for the migration check.
  task(:abort_if_pending_migrations).clear_prerequisites

  # Fix that we need to connect to the dev database.
  task :abort_if_pending_migrations => :mysql_inspector_connect_to_dev
  task :mysql_inspector_connect_to_dev do
    ActiveRecord::Base.establish_connection(:development)
  end


  namespace :test do

    #
    # Rewrite the public db:prepare task.
    #

    # Totally reset the db:test:prepare task.
    task(:prepare).clear_prerequisites.clear_actions

    # Redefine db:test:prepare to load the mysql_inspector structure.
    task :prepare => ["db:test:purge", "db:abort_if_pending_migrations", "db:mysql_inspector:load_to_test"]
  end


  #
  # mysql_inspector tasks.
  #

  namespace :mysql_inspector do

    desc "Write the current development database to db/current"
    task :dump => :environment do
      mysql_inspector_config("development").write_dump("current")
    end

    desc "Load the development database from db/current"
    task :load => [:environment, :load_config] do
      mysql_inspector_config("development").load_dump("current")
    end

    # Internal: Load the test database from db/current.
    task :load_to_test do
      mysql_inspector_config("test").load_dump("current")
    end
  end

end
