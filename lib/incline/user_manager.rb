
module Incline
  ##
  # Handles the user management tasks between an authentication system and the database.
  #
  # The default authentication system is the database, but other systems are supported.
  # Out of the box we support LDAP, but the class can be extended to add other functionality.
  #
  class UserManager

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
    # The 'engines' key will have engine names as the subkeys.  These should be in underscore
    # format.  And each subkey will be an array of domain names to register to the engine.
    #
    #     {
    #       :engines => {
    #         'example_engine' => [
    #           'example.com',
    #           'example.net'
    #         ],
    #         'my_gem/my_engine' => [
    #           'example.org'
    #         ]
    #       }
    #     }
    #
    def initialize(options = {})
      @options = (options || {}).deep_symbolize_keys
      Incline::User.ensure_admin_exists!

      if @options[:engines].is_a?(::Hash)
        @options[:engines].each do |engine_name, domain_list|
          domain_list = [ domain_list ] unless domain_list.is_a?(::Array)
          engine =
              begin
                engine_name.classify.constantize
              rescue NameError
                nil
              end

          if engine
            register_auth_engine engine, *domain_list
          end

        end
      end
    end

    ##
    # Attempts to authenticate the user and returns the model on success.
    def authenticate(email, password, client_ip)
      return nil unless Incline::EmailValidator.valid?(email)
      email = email.downcase

      # If an engine is registered for the email domain, then use it.
      engine = get_auth_engine(email)
      if engine
        engine = engine.new(@options)
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
      raise ArgumentError, "The 'engine' parameter must be a class." unless engine.is_a?(::Class) || engine.nil?
      domains.map do |dom|
        dom.to_s.downcase.strip
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
      default.register_auth_engine engine, *domains
    end
    
    ##
    # Clears any registered authentication engine for one or more domains.
    def clear_auth_engine(*domains)
      register_auth_engine nil, *domains
    end
    
    ##
    # Clears any registered authentication engine for one or more domains.
    def self.clear_auth_engine(*domains)
      default.clear_auth_engine *domains
    end

    private

    def auth_engines
      @auth_engines ||= { }
    end

    def get_auth_engine(email)
      dom = email.partition('@')[2].downcase
      auth_engines[dom]
    end

    def purge_old_history_for(user, max_months = 2)
      user.login_histories.where('"incline_user_login_histories"."created_at" <= ?', Time.zone.now - max_months.months).delete_all
    end

    def add_failure_to(user, message, client_ip)
      Incline::Log::info "LOGIN(#{user}) FAILURE FROM #{client_ip}: #{message}"
      history_length = 2
      unless user.is_a?(::Incline::User)
        message = "[email: #{user}] #{message}"
        user = User.anonymous
        history_length = 6
      end
      purge_old_history_for user, history_length
      user.login_histories.create(ip_address: client_ip, successful: false, message: message)
    end

    def add_success_to(user, message, client_ip)
      Incline::Log::info "LOGIN(#{user}) SUCCESS FROM #{client_ip}: #{message}"
      purge_old_history_for user
      user.login_histories.create(ip_address: client_ip, successful: true, message: message)
    end

    def self.auth_config
      @auth_config ||=
          begin
            cfg = Rails.root.join('config','auth.yml')
            if File.exist?(cfg)
              cfg = YAML.load_file(cfg)
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
