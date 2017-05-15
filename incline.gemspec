$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'incline/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name                    = 'incline'
  s.version                 = Incline::VERSION
  s.authors                 = ['Beau Barker']
  s.email                   = ['beau@barkerest.com']
  s.homepage                = 'http://www.barkerest.com/'
  s.summary                 = 'A gem designed to get off to an even quicker start with Rails.'
  s.license                 = 'MIT'
  s.files                   = `git ls-files -z`.split("\x0").reject{|f| f == 'incline.gemspec'}
  s.require_path            = 'lib'
  s.bindir                  = 'exe'
  s.executables             = %w()
  s.required_ruby_version   = '>= 2.3.0'

  s.add_dependency 'rails',                         '~> 4.2.8'
  s.add_dependency 'sass-rails',                    '~> 5.0.6'
  s.add_dependency 'coffee-rails',                  '~> 4.2.1'
  s.add_dependency 'jquery-rails',                  '~> 4.3.1'
  s.add_dependency 'jbuilder',                      '~> 2.6.3'
  s.add_dependency 'uglifier',                      '~> 3.2.0'
  s.add_dependency 'bootstrap-sass',                '~> 3.3.7'
  s.add_dependency 'will_paginate',                 '~> 3.1.5'
  s.add_dependency 'bootstrap-will_paginate',       '~> 1.0.0'
  s.add_dependency 'bcrypt',                        '~> 3.1.11'
  s.add_dependency 'nokogiri',                      '~> 1.7.1'
  s.add_dependency 'spawnling',                     '~> 2.1.6'
  s.add_dependency 'shells',                        '~> 0.1.9'
  s.add_dependency 'ansi',                          '~> 1.5.0'
  s.add_dependency 'exception_notification',        '~> 4.2.1'
  s.add_dependency 'redcarpet',                     '~> 3.4.0'
  s.add_dependency 'net-ldap',                      '~> 0.16.0'

  s.add_development_dependency 'sqlite3',                         '~> 1.3.13'
  s.add_development_dependency 'faker',                           '~> 1.7.3'
  s.add_development_dependency 'web-console',                     '~> 3.3.0'
  s.add_development_dependency 'byebug',                          '~> 9.0.6'
  s.add_development_dependency 'tiny_tds',                        '~> 1.3.0'
  s.add_development_dependency 'activerecord-sqlserver-adapter',  '~> 4.2.18'

end
