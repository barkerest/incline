require 'erb'

module Incline
  ##
  # Handles the user management tasks between an authentication system and the database.
  #
  # The default authentication system is the database, but other systems are supported.
  # Out of the box we support LDAP, but the class can be extended to add other functionality.
  #
  class UserManager < AuthEngineBase

    ##
    # Creates a new user manager.
    #
    # The user manager itself takes no options, however options will be passed to
    # any registered authentication engines when they are instantiated.
    #
    # The options can be used to pre-register engines and provide configuration for them.
    # The engines will have specific configurations, but the UserManager class recognizes
    # the 'engines' key.
    #
    #     {
    #       :engines => {
    #         'example.com' => {
    #           :engine => MySuperAuthEngine.new(...)
    #         },
    #         'example.org' => {
    #           :engine => 'incline_ldap/auth_engine',
    #           :config => {
    #             :host => 'ldap.example.org',
    #             :port => 636,
    #             :base_dn => 'DC=ldap,DC=example,DC=org'
    #           }
    #         }
    #       }
    #     }
    #
    # When an 'engines' key is processed, the configuration options for the engines are pulled
    # from the subkeys.  Once the processing of the 'engines' key is complete, it will be removed
    # from the options hash so any engines registered in the future will not receive the extra options.
    def initialize(options = {})
      @options = (options || {}).deep_symbolize_keys
      Incline::User.ensure_admin_exists!

      if @options[:engines].is_a?(::Hash)
        @options[:engines].each do |domain_name, domain_config|
          if domain_config[:engine].blank?
            ::Incline::Log::info "Domain #{domain_name} is missing an engine definition and will not be registered."
          elsif domain_config[:engine].is_a?(::Incline::AuthEngineBase)
            ::Incline::Log::info "Using supplied auth engine for #{domain_name}."
            register_auth_engine domain_config[:engine], domain_name
          else
            engine =
                begin
                  domain_config[:engine].to_s.classify.constantize
                rescue NameError
                  nil
                end

            if engine
              engine = engine.new(domain_config[:config] || {})
              if engine.is_a?(::Incline::AuthEngineBase)
                ::Incline::Log::info "Using newly created auth engine for #{domain_name}."
                register_auth_engine engine, domain_name
              else
                ::Incline::Log::warn "Object created for #{domain_name} does not inherit from Incline::AuthEngineBase."
              end
            else
              ::Incline::Log::warn "Failed to create auth engine for #{domain_name}."
            end
          end
        end
      end

      @options.delete(:engines)

    end

    ##
    # Attempts to authenticate the user and returns the model on success.
    def authenticate(email, password, client_ip)
      return nil unless Incline::EmailValidator.valid?(email)
      email = email.downcase

      # If an engine is registered for the email domain, then use it.
      engine = get_auth_engine(email)
      if engine
        return engine.authenticate(email, password, client_ip)
      end

      # Otherwise we will be using the database.
      user = User.find_by(email: email)
      if user
        # user must be enabled and the password must match.
        unless user.enabled?
          add_failure_to user, '(DB) account disabled', client_ip
          return nil
        end
        if user.authenticate(password)
          add_success_to user, '(DB)', client_ip
          return user
        else
          add_failure_to user, '(DB) invalid password', client_ip
          return nil
        end
      end
      add_failure_to email, 'invalid email', client_ip
      nil
    end

    ##
    # Attempts to authenticate the user and returns the model on success.
    def self.authenticate(email, password, client_ip)
      default.authenticate email, password, client_ip
    end

    ##
    # Registers an authentication engine for one or more domains.
    #
    # The +engine+ passed in should take an options hash as the only argument to +initialize+
    # and should provide an +authenticate+ method that takes the +email+, +password+, and
    # +client_ip+.
    #
    # The +authenticate+ method of the engine should return an Incline::User object on success or nil on failure.
    #
    #   class MyAuthEngine
    #     def initialize(options = {})
    #       ...
    #     end
    #
    #     def authenticate(email, password, client_ip)
    #       ...
    #     end
    #   end
    #
    #   Incline::UserManager.register_auth_engine(MyAuthEngine, 'example.com', 'example.net', 'example.org')
    #
    def register_auth_engine(engine, *domains)
      unless engine.nil?
        unless engine.is_a?(::Incline::AuthEngineBase)
          raise ArgumentError, "The 'engine' parameter must be an instance of an auth engine or a class defining an auth engine." unless engine.is_a?(::Class)
          engine = engine.new(@options)
          raise ArgumentError, "The 'engine' parameter must be an instance of an auth engine or a class defining an auth engine." unless engine.is_a?(::Incline::AuthEngineBase)
        end
      end
      domains.map do |dom|
        dom = dom.to_s.downcase.strip
        raise ArgumentError, "The domain #{dom.inspect} does not appear to be a valid domain." unless dom =~ /\A[a-z0-9]+(?:[-.][a-z0-9]+)*\.[a-z]+\Z/
        dom
      end.each do |dom|
        auth_engines[dom] = engine
      end
    end

    ##
    # Registers an authentication engine for one or more domains.
    #
    # The +engine+ passed in should take an options hash as the only argument to +initialize+
    # and should provide an +authenticate+ method that takes the +email+, +password+, and
    # +client_ip+.
    #
    # The +authenticate+ method of the engine should return an Incline::User object on success or nil on failure.
    def self.register_auth_engine(engine, *domains)
      default.register_auth_engine(engine, *domains)
    end
    
    ##
    # Clears any registered authentication engine for one or more domains.
    def clear_auth_engine(*domains)
      register_auth_engine(nil, *domains)
    end
    
    ##
    # Clears any registered authentication engine for one or more domains.
    def self.clear_auth_engine(*domains)
      default.clear_auth_engine(*domains)
    end

    private

    def auth_engines
      @auth_engines ||= { }
    end

    def get_auth_engine(email)
      dom = email.partition('@')[2].downcase
      auth_engines[dom]
    end

    def self.auth_config
      @auth_config ||=
          begin
            cfg = Rails.root.join('config','auth.yml')
            if File.exist?(cfg)
              cfg = YAML.load(ERB.new(File.read(cfg)).result)
              if cfg.is_a?(::Hash)
                cfg = cfg[Rails.env]
                (cfg || {}).symbolize_keys
              else
                {}
              end
            else
              {}
            end
          end
    end

    def self.default
      @default ||= UserManager.new(auth_config)
    end

  end
end
