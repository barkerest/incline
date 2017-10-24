# Basic functionality
require 'incline/errors'
require 'incline/work_path'
require 'incline/json_log_formatter'
require 'incline/json_logger'
require 'incline/global_status'
require 'incline/data_tables_request'
require 'incline/recaptcha'
require 'incline/auth_engine_base'
require 'incline/user_manager'
require 'incline/constant_enum'
require 'incline/bit_enum'

# Preloaded gems
require 'rails'
require 'jbuilder'
require 'jquery-rails'
require 'bootstrap-sass'
require 'exception_notification'

# Class extensions
require 'incline/extensions/object'
require 'incline/extensions/numeric'
require 'incline/extensions/string'
require 'incline/extensions/application'
require 'incline/extensions/application_configuration'
require 'incline/extensions/active_record_base'
require 'incline/extensions/connection_adapter'
require 'incline/extensions/main_app'
require 'incline/extensions/action_controller_base'
require 'incline/extensions/current_request'
require 'incline/extensions/action_mailer_base'
require 'incline/extensions/action_view_base'
require 'incline/extensions/session'
require 'incline/extensions/resource_route_generator'
require 'incline/extensions/erb_scaffold_generator'
require 'incline/extensions/jbuilder_generator'
require 'incline/extensions/jbuilder_template'
require 'incline/extensions/form_builder'
require 'incline/extensions/test_case'
require 'incline/extensions/integer_value'
require 'incline/extensions/float_value'
require 'incline/extensions/decimal_value'
require 'incline/extensions/date_time_value'
require 'incline/extensions/date_value'
require 'incline/extensions/param_propagation'

# Validators
require 'incline/validators/email_validator'
require 'incline/validators/safe_name_validator'
require 'incline/validators/ip_address_validator'
require 'incline/validators/recaptcha_validator'

# Models
require_relative '../../app/models/incline/access_group'
require_relative '../../app/models/incline/action_security'
require_relative '../../app/models/incline/user'


module Incline

  ##
  # The Incline engine.
  class Engine < ::Rails::Engine
    isolate_namespace Incline

    ##
    # If you want to report valid permissions on access denied, set this attribute to true.
    cattr_accessor :show_valid_permissions


    # pre-init, should hopefully be run before other gem initializers.
    Rails::Application::Bootstrap::initializer '00.incline_preinit' do
      Incline::Log::info "Initializing #{Rails.application.app_info}"
      Incline::Log::info ">> Incline v#{Incline::VERSION}"

      Incline::Engine::set_date_formats
      Incline::Engine::apply_email_config_to self
    end

    # main initializer.
    initializer '00.incline_init' do |app|
      # Silence rvm backtraces.
      Rails.backtrace_cleaner.add_silencer { |line| line =~ /rvm/ }

      # Set the session cookie name.
      app.config.session_store :cookie_store, key: app.cookie_name('session')

      # Configure the app to work with the library.
      Incline::Engine::add_helpers_to app
      Incline::Engine::add_assets_to app
      Incline::Engine::notify_on_exceptions_from app
      Incline::Engine::add_migrations_to app
      Incline::Engine::add_seeds_to app
      Incline::Engine::configure_generators_for app


    end


    ##
    # Sets the date formats to default to US format (ie - m/d/y)
    def self.set_date_formats
      # add American formats as default.
      Time::DATE_FORMATS[:default] = '%m/%d/%Y %H:%M'
      Time::DATE_FORMATS[:date] = '%m/%d/%y'

      Date::DATE_FORMATS[:default] = '%m/%d/%Y'
      Date::DATE_FORMATS[:date] = '%m/%d/%y'
    end

    ##
    # Configures the application to include Incline helpers.
    def self.add_helpers_to(app)
      # add our helper path to the search path.
      path = File.expand_path('../../../app/helpers', __FILE__)
      app.helpers_paths << path unless app.helpers_paths.include?(path)
      app.config.paths['app/helpers'] << path unless app.config.paths['app/helpers'].include?(path)
    end

    ##
    # Configures the application to include Incline assets.
    def self.add_assets_to(app)
      # Add our assets
      app.config.assets.precompile += %w(
          incline/barcode-B.svg
      )
    end

    ##
    # Configures the application to use the Incline email configuration.
    #
    # If the +config/email.yml+ file is not configured correctly this does nothing.
    def self.apply_email_config_to(app)
      if Incline::email_config.valid?
        app.config.action_mailer.default_url_options = {
            host: Incline::email_config[:default_url]
        }
        app.config.action_mailer.default_options = {
            from: Incline::email_config[:sender],
            to:   Incline::email_config[:default_recipient]
        }
        app.config.action_mailer.smtp_settings = {
            address:                Incline::email_config[:server],
            port:                   Incline::email_config[:port],
            user_name:              Incline::email_config[:user],
            password:               Incline::email_config[:password],
            authentication:         Incline::email_config[:user].blank? ? nil : Incline::email_config[:auth],
            enable_start_tls_auto:  Incline::email_config[:start_tls],
            ssl:                    Incline::email_config[:ssl],
            openssl_verify_mode:    'none'
        }
        if Rails.env.test?
          app.config.action_mailer.delivery_method = :test
        else
          app.config.action_mailer.delivery_method = :smtp
          app.config.action_mailer.raise_delivery_errors = true
          app.config.perform_deliveries = true
        end
      end
    end

    ##
    # Configures the application to send messages when unhandled exceptions occur in production mode.
    def self.notify_on_exceptions_from(app)
      # Send emails for unhandled exceptions.
      if Rails.env.production?
        app.config.middleware.use(
            ExceptionNotification::Rack,
            email: {
                email_prefix: '[Incline ' + Rails.application.app_info + ']',
                sender_address: Incline::email_config[:sender],
                exception_recipients: [ Incline::email_config[:exception_recipient] || Incline::email_config[:default_recipient] ]
            }
        )
      end
    end

    ##
    # Configures the application to use Incline migrations as opposed to copying the Incline migrations locally.
    def self.add_migrations_to(app)
      unless app.root.to_s.match root.to_s
        migrate_path = File.expand_path('../../../db/migrate', __FILE__)

        # this should be all that's required.
        app.config.paths['db/migrate'] << migrate_path unless app.config.paths['db/migrate'].include?(migrate_path)

        # however this gets set before the config is updated.
        # so we'll add it here as well to ensure it gets set correctly.
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths << migrate_path unless ActiveRecord::Tasks::DatabaseTasks.migrations_paths.include?(migrate_path)
      end
    end

    ##
    # Configures the application to use Incline seeds.
    def self.add_seeds_to(app)
      seeds_path = File.expand_path('../../../db/seeds.rb', __FILE__)

      # Once again, this should be all that's required.
      app.config.paths['db/seeds.rb'] << seeds_path unless app.config.paths['db/seeds.rb'].include?(seeds_path)
    end

    ##
    # Configures generators so they can use our templates and so they don't create some redundant files.
    def self.configure_generators_for(app)
      app.config.app_generators.templates << File.expand_path('../../templates', __FILE__)
      app.config.generators do |g|
        g.scaffold_stylesheet   false   # we depend on the application.css, no need for a scaffold.css
        g.stylesheets           false   # no need for a stylesheet for every controller.
        g.javascripts           false   # no need for a javascript file for every controller.
      end
    end


  end
end
