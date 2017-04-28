require 'incline/version'
require 'incline/log'
require 'incline/engine'

##
# A Rails quick start library.
module Incline

  ##
  # Gets the automatic email configuration for the Incline application.
  #
  # The primary configuration should be stored in +config/email.yml+.
  # If this file is missing, automatic email configuration is skipped and must be manually specified in your
  # application's environment initializer (eg - config/environment/production.rb).
  #
  #   test:
  #     ...
  #   development:
  #     ...
  #   production:
  #     default_url: www.example.com
  #     default_recipient: contact@example.com
  #     sender: noreply@example.com
  #     auth: :plain
  #     start_tls: true
  #     ssl: false
  #     server: smtp.example.com
  #     port: 587
  #
  # You shouldn't use an open relay, a warning will be thrown if you do.
  # But you don't want your login credentials stored in +config/email.yml+ either.
  # Instead, credentials (if any) should be stored in +config/secrets.yml+.
  #
  #   test:
  #     ...
  #   development:
  #     ...
  #   production:
  #     email:
  #       user: noreply@example.com
  #       password: super-secret-password
  #     secret_key_base: ...
  #
  def self.email_config
    @email_config ||=
        begin
          yaml = Rails.root.join('config', 'email.yml')
          if File.exist?(yaml)
            cfg = File.exist?(yaml) ? YAML.load_file(yaml) : { }
            cfg = (cfg[Rails.env] || {}).symbolize_keys

            cfg = {
                port: 25,
                auth: :plain,
                start_tls: true,
                ssl: false
            }.merge(cfg)

            Incline::Log::warn 'The "user" key for the email configuration should be in "secrets.yml" instead of "email.yml".' unless cfg[:user].blank?
            Incline::Log::warn 'The "password" key for the email configuration should be in "secrets.yml" instead of "email.yml".' unless cfg[:password].blank?

            cred = (Rails.application.secrets[:email] || {}).symbolize_keys.select{|k,_| [:user, :password, :auth].include? k }
            cfg.merge! cred

            Incline::Log::warn 'The email configuration is missing the "user" key.' if cfg[:user].blank?
            Incline::Log::warn 'The email configuration is missing the "password" key.' if cfg[:password].blank?
            Incline::Log::error 'The email configuration is missing the "server" key.' if cfg[:server].blank?
            Incline::Log::error 'The email configuration is missing the "sender" key.' if cfg[:sender].blank?
            Incline::Log::error 'The email configuration is missing the "default_url" key.' if cfg[:default_url].blank?
            Incline::Log::error 'The email configuration is missing the "default_recipient" key.' if cfg[:default_recipient].blank?

            def cfg.valid?
              return false if self[:sender].blank? || self[:server].blank? || self[:default_url].blank? || self[:default_recipient].blank?
              true
            end

            cfg.freeze
          else
            Incline::Log::info 'The configuration file "email.yml" does not exist, automatic email configuration disabled.'
            cfg = {}

            def cfg.valid?
              false
            end

            cfg.freeze
          end
        end
  end

end
