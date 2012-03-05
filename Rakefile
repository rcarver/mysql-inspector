load "Rakefile.base"

require 'rake/testtask'

task :test => [:test_default, :test_ar]

Rake::TestTask.new(:test_default) do |t|
  t.libs.push "lib", "test"
  t.pattern = 'test/mysql_inspector/**/*_test.rb'
end

Rake::TestTask.new(:test_ar) do |t|
  t.libs.push "lib", "test"
  t.pattern = 'test/mysql_inspector_ar/**/*_test.rb'
end


def load_schema(name)
  $LOAD_PATH.unshift "test"
  require 'helpers/mysql_schemas'
  require 'helpers/mysql_utils'

  schemas = Object.new
  schemas.extend MysqlSchemas

  MysqlUtils.create_mysql_database("mysql_inspector_development", schemas.send(name))
end

task :db1 do
  load_schema(:schema_a)
end

task :db2 do
  load_schema(:schema_b)
end
