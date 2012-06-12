mysql_inspector_db_namespace = namespace :db do

  def mysql_inspector_config(database=nil)
    config = MysqlInspector::Config.new
    config.rails!
    config.database_name = database if database
    config
  end

  # Totally reset the setup task.
  task(:setup).clear_prerequisites.clear_actions

  # Redefine the setup task to use mysql_inspector.
  task :setup => ['db:create', 'mysql_inspector:load']

  # Totally reset the _dump task.
  task(:_dump).clear_prerequisites.clear_actions

  # Redefine the dump task to always call mysql_inspector:dump.
  task :_dump => "db:mysql_inspector:dump" do
    # Allow this task to be called as many times as required. An example is the
    # migrate:redo task, which calls other two internally that depend on this one.
    mysql_inspector_db_namespace['_dump'].reenable
  end

  namespace :mysql_inspector do
    task :dump => :environment do
      mysql_inspector_config("development").write_dump("current")
    end
    task :load => [:environment, :load_config] do
      mysql_inspector_config("development").load_dump("current")
    end
  end

  namespace :test do

    # Replace the test:prepare task actions.
    task(:prepare).clear_actions
    task :prepare => "test:mysql_inspector_load"

    task :mysql_inspector_load => "db:test:purge" do
      mysql_inspector_config("test").load_dump("current")
    end
  end
end
