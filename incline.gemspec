$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'incline/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name                    = 'incline'
  s.version                 = Incline::VERSION
  s.authors                 = ['Beau Barker']
  s.email                   = ['beau@barkerest.com']
  s.homepage                = 'https://github.com/barkerest/incline/'
  s.summary                 = 'A gem designed to get off to an even quicker start with Rails.'
  s.license                 = 'MIT'
  s.files                   = `git ls-files -z`.split("\x0").reject{|f| f == 'incline.gemspec'}
  s.require_path            = 'lib'
  s.bindir                  = 'exe'
  s.executables             = %w(new_incline_app)
  s.required_ruby_version   = '>= 2.3.0'

  s.add_dependency 'rails',                         '~> 4.2.8'
  s.add_dependency 'sass-rails',                    '~> 5.0.6'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jbuilder'
  s.add_dependency 'uglifier'
  s.add_dependency 'bootstrap-sass'
  s.add_dependency 'bcrypt'
  s.add_dependency 'nokogiri'
  s.add_dependency 'spawnling',                     '~> 2.1.6'
  s.add_dependency 'shells',                        '~> 0.1.9'
  s.add_dependency 'ansi',                          '~> 1.5.0'
  s.add_dependency 'exception_notification',        '~> 4.2.1'
  s.add_dependency 'redcarpet',                     '~> 3.4.0'

  s.add_development_dependency 'sqlite3',                         '~> 1.3.13'
  s.add_development_dependency 'faker',                           '~> 1.7.3'
  s.add_development_dependency 'web-console',                     '~> 3.3.0'

end
