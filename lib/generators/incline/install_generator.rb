require 'rails/generators'

module Incline

  class InstallGenerator < ::Rails::Generators::Base

    desc "This generator will update your application for use with the Incline gem."

    class_option :mount_path, type: :string, default: 'incline', desc: 'Determines where the Incline engine will mount its routes.'
    class_option :force_copy, type: :boolean, default: true, desc: 'Determines if certain files will be forcibly copied.'
    class_option :json_logger, type: :boolean, default: true, desc: 'Determines if the JSON logger should be enabled.'

    source_root File.expand_path('../templates', __FILE__)

    def install_module

      mount_path = options[:mount_path] || 'incline'
      # trim off leading '/', './', or '../'.
      # also trim off trailing '/'.
      mount_path = mount_path.to_s.gsub('\\','/').gsub(/^\.*\//, '').gsub(/\/+$/, '')
      mount_path = 'incline' if mount_path.blank?
      @mount_path = '/' + mount_path

      copy_files
      add_version
      config_app
      config_logger if options[:json_logger]
      config_routes
      config_gitignore
      config_secrets

    end


    private

    def copy_files
      # We just copy these files outright because they override the default behaviors and shouldn't need modification
      force = options[:force_copy] ? { force: true } : { skip: true }
      {
          'incline_application.js' => 'app/assets/javascripts/application.js',
          'incline_application.css' => 'app/assets/stylesheets/application.css',
          'incline_application.html.erb' => 'app/views/layouts/application.html.erb',
          'incline_mailer.html.erb' => 'app/views/layouts/mailer.html.erb',
          'incline_mailer.text.erb' => 'app/views/layouts/mailer.text.erb',
          'incline_users.yml' => 'test/fixtures/incline/users.yml',
      }.each do |source,destination|
        copy_file source, destination, force
      end

      # We copy these files if they don't exist.
      {
          'incline_email.yml' => 'config/email.yml',
          'incline_database.yml' => 'config/database.yml',
          '_app_menu_anon.html.erb' => 'app/views/layouts/incline/_app_menu_anon.html.erb',
          '_app_menu_authenticated.html.erb' => 'app/views/layouts/incline/_app_menu_authenticated.html.erb',
      }.each do |source,destination|
        copy_file source, destination, skip: true
      end
    end

    def config_app
      if File.exist?('config/application.rb')
        contents = File.read('config/application.rb')
        changed = false
        unless contents =~ /def\s+app_name\s/ && contents =~ /def\s+app_version\s/
          match = (/module\s+([a-z0-9_:]*)\s+class\s+application/i).match(File.read('config/application.rb'))
          if match
            new_data = ''
            unless contents =~ /def\s+app_name\s/
              new_data += <<-EOD

    # This is your application name.  Set it as appropriate.
    def app_name
      "#{match[1]}"
    end

              EOD
            end
            unless contents =~ /def\s+app_version\s/
              new_data += <<-EOD

    # This is your application version.  Change it in 'version.rb'.
    def app_version
      #{match[1]}::VERSION
    end

              EOD
            end
            changed = true
            insert_into_file 'config/application.rb', new_data, after: /class\s+Application\s+<\s+(::)?Rails::Application\n/m
          end
        end

        unless contents =~ /require_relative\s*['"]\.\/version['"]/
          changed = true
          prepend_to_file 'config/application.rb', "require_relative './version'\n"
        end

        unless changed
          say_status :ok, 'config/application.rb', :blue
        end
      else
        say_status :missing, 'config/application.rb', :red
      end
    end

    def add_version
      # Make sure a version.rb file exists.
      template 'incline_version.rb', 'config/version.rb', skip: true
    end

    def config_logger
      # Change the production environment to use JsonLogFormatter instead of Logger::Formatter
      # NOTE: We are switching to using Incline::JsonLogger but we will leave this gsub in place
      # to keep the options open for the end user (if they want to change loggers, but use the same formatter).
      # The log formatter must be set after the logger.
      gsub_file 'config/environments/production.rb',  /\n\s*config\.log_formatter\s*=\s*(::)?Logger::Formatter.new/m, <<-EOS

  # config.log_formatter = ::Logger::Formatter.new
  
  # Incline::JsonLogFormatter also includes the PID and timestamp, plus it makes the log easier to parse.
  # If you want to revert to using the standard formatter above, uncomment that line and comment out this line instead.
  config.log_formatter = ::Incline::JsonLogFormatter.new
      EOS

      %w(config/environments/development.rb config/environments/test.rb config/environments/production.rb).each do |cfg|
        if File.exist?(cfg)
          contents = File.read(cfg)
          
          if contents =~ /\n\s*config.logger\s*=/m
            # a logger is already explicitly configured.
            say_status :ok, cfg, :blue
          elsif contents =~ /\n\s*config.log_formatter\s*=/m
            # a log formatter is configured, so configure a logger with rotation and use the existing formatter.
            gsub_file cfg, /\n\s*config.log_formatter\s*=([^\n]*)/m, <<-EOS

  config.logger = ::ActiveSupport::Logger.new(config.paths['log'].first, 2, 5.megabytes)
  config.logger.formatter =\\1
            EOS
          else
            # no log formatter or logger is configured, so configure a JsonLogger with rotation.
            insert_into_file cfg, "\n  config.logger = ::Incline::JsonLogger.new(config.paths['log'].first, 2, 5.megabytes)\n", before: /end\s*\Z/m
          end
        else
          say_status :missing, cfg, :red
        end
      end
    end

    def config_routes
      if File.exist?('config/routes.rb')
        contents = File.read('config/routes.rb')
        if contents =~ /mount\s*(::)?Incline::Engine/
          say_status :ok, 'config/routes.rb', :blue
        else
          insert_into_file 'config/routes.rb', "\n  mount ::Incline::Engine => #{@mount_path.inspect}\n", after: /routes\.draw\s*(do|\{)/
        end
      else
        say_status :missing, 'config/routes.rb', :red
      end
    end

    def config_gitignore
      if File.exist?('.gitignore')
        contents = File.read('.gitignore')
        changed = false

        unless contents =~ /^\*\*\/\.byebug\*$/
          changed = true
          append_to_file '.gitignore', "\n**/.byebug*\n"
        end

        unless contents =~ /^config\/secrets\.yml$/
          changed = true
          append_to_file '.gitignore', "\nconfig/secrets.yml\n"
        end

        unless changed
          say_status :ok, '.gitignore', :blue
        end
      else
        unless options[:pretend]
          File.write '.gitignore', <<-EOF
**/.byebug*
.bundle/
config/secrets.yml
db/*.sqlite3
db/*.sqlite3-journal
log/*.log
tmp/
vendor/bundle/
          EOF
        end
        say_status :create, '.gitignore', :green
      end
    end

    def config_secrets
      if File.exist?('config/secrets.yml')
        contents = File.read('config/secrets.yml')
        changed = false
        missing_alias = /^(default:\s*\n)/m
        valid_alias = /^default:\s+&default\s*\n/m

        unless contents =~ valid_alias
          if contents =~ missing_alias
            # section exists, but is missing the &default label
            flag = $1
            changed = true
            contents.gsub! /^#{flag}/, "default: &default\n"
          else
            # section does not exist.
            changed = true
            to_insert =  <<-EOF
default: &default
  # define your recaptcha keys.
  recaptcha_public:
  recaptcha_private:
  # define your email credentials.
  email:
    user: no-reply@example.com
    password: MySecretPassword

            EOF
            
            contents = to_insert + contents
          end
        end

        # now ensure the three environments are set to inherit from default.
        %w(development test production).each do |section|
          missing_alias = /^(#{section}:\s*\n)/m
          valid_alias = /^#{section}:\s*\n  <<:\s*\*default\s*\n/m
          unless contents =~ valid_alias
            if contents =~ missing_alias
              flag = $1
              changed = true
              contents.gsub! /^#{flag}/, "\\0  <<: *default\n"
            else
              say_status :missing, "config/secrets.yml [#{section}]", :red
            end
          end
        end

        if changed
          unless options[:pretend]
            File.write 'config/secrets.yml', contents
          end
          say_status :modify, 'config/secrets.yml', :green
        else
          say_status :ok, 'config/secrets.yml', :blue
        end
      end
    end


  end
end