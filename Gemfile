source 'https://rubygems.org'

# Declare your gem's dependencies in incline.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :development do
  gem 'byebug'
  gem 'tzinfo-data',  platform: [ :mswin, :mingw, :x64_mingw ]
end

group :test do
  gem 'byebug'
  gem 'tiny_tds',                        '~> 1.3.0'
  gem 'activerecord-sqlserver-adapter',  '~> 4.2.18'
end

