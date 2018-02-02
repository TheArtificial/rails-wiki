$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "wiki/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-wiki"
  s.version     = Wiki::VERSION
  s.authors     = ["Hans Gerwitz"]
  s.email       = ["info@theartificial.nl"]
  s.homepage    = "http://github.com/TheArtificial"
  s.summary     = "A Rails wiki engine"
  s.description = "This engine uses gollum-lib to provide a very basic, opinionated wiki stored as a git repository."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'gollum-lib', '~> 4.1'
  s.add_dependency 'gollum-rugged_adapter', '~> 0.4.2' # 0.4.4 breaks search: issue #24
  s.add_dependency 'redcarpet', '~> 3.4'
end
