# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mysql_inspector/version"

Gem::Specification.new do |s|
  s.name        = "mysql-inspector"
  s.version     = MysqlInspector::VERSION
  s.authors     = ["Ryan Carver"]
  s.email       = ["ryan@ryancarver.com"]
  s.homepage    = ""
  s.summary     = %q{Store and understand your MySQL schema}
  s.description = %q{Store and understand your MySQL schema}

  s.rubyforge_project = "mysql-inspector"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest"

  # s.add_runtime_dependency "rest-client"
end
