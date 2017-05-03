module Incline::Extensions
  ##
  # Creates a default database configuration to use when config/database.yml is not present.
  module ApplicationConfiguration

    ##
    # Override the +database_configuration+ method to return something in development mode if
    # the +config/database.yml+ file is missing.
    #
    # A warning will be logged if the default configuration is used.  In production mode, an
    # exception will be bubbled up.
    #
    # The default configuration for test and development environments is to use a sqlite
    # database in the db folder using the environment name (eg - db/development.sqlite).
    #
    # The primary purpose of this is to allow +rake+ and +rails+ actions that may not depend on the
    # database configuration or may actually be used to generate the configuration file.
    def self.included(base) #:nodoc:
      base.class_eval do
        alias :incline_original_database_configuration :database_configuration

        def database_configuration
          begin
            incline_original_database_configuration
          rescue
            raise unless $!.inspect.include?('No such file -') && (!Rails.env.production?)

            default = {
                'adapter' => 'sqlite3',
                'pool' => 5,
                'timeout' => 5000
            }

            Incline::Log::warn "Providing default database configuration for #{Rails.env} environment."

            {
                'test' => default.merge('database' => 'db/test.sqlite'),
                'development' => default.merge('database' => 'db/development.sqlite')
            }
          end
        end
      end
    end

  end
end

Rails::Application::Configuration.include Incline::Extensions::ApplicationConfiguration