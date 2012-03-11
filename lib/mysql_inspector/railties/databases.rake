namespace :db do

  def mysql_inspector_config(database=nil)
    config = MysqlInspector::Config.new
    config.rails!
    config.database_name = database if database
    config
  end

  # Splice mysql_inspector task into db:setup.
  task(:setup).prerequisites.unshift('db:mysql_inspector:load')

  # Totally reset the _dump task.
  task(:_dump).clear_prerequisites.clear_actions

  # Redefine the dump task to always call mysql_inspector:dump.
  task :_dump => "db:mysql_inspector:dump" do
    # Allow this task to be called as many times as required. An example is the
    # migrate:redo task, which calls other two internally that depend on this one.
    db_namespace['_dump'].reenable
  end

  namespace :mysql_inspector do
    task :dump => :environment do
      mysql_inspector_config.write_dump("current")
    end
    task :load => :environment do
      mysql_inspector_config.load_dump("current")
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
