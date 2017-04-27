$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'incline/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'incline'
  s.version     = Incline::VERSION
  s.authors     = ['Beau Barker']
  s.email       = ['beau@barkerest.com']
  s.homepage    = 'http://www.barkerest.com/'
  s.summary     = 'A gem designed to get off to a quicker start with Rails.'
  s.license     = 'MIT'

  s.files = `git ls-files -z`.split("\x0")
  s.files.delete 'incline.gemspec'


  s.add_dependency 'rails',         '~> 4.2.8'


  s.add_development_dependency 'sqlite3'

end
