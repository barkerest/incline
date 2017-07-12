
module Incline

  ##
  # Defines an auth engine.
  class AuthEngineBase

    ##
    # The auth engine initializer should take a hash of parameters.
    def initialize(options = {})
      @options = options || {}
    end

    ##
    # The authenticate method takes an email and password to authenticate a user and the client IP for logging purposes.
    def authenticate(email, password, client_ip)
      nil
    end

    protected

    ##
    # Logs a failure message for a user.  The user can either be an Incline::User model or the email address used
    # in the attempt.
    def add_failure_to(user, message, client_ip) # :doc:
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

    ##
    # Logs a success message for a user.
    def add_success_to(user, message, client_ip)  # :doc:
      Incline::Log::info "LOGIN(#{user}) SUCCESS FROM #{client_ip}: #{message}"
      purge_old_history_for user
      user.login_histories.create(ip_address: client_ip, successful: true, message: message)
    end

    private

    def purge_old_history_for(user, max_months = 2)
      user.login_histories.where('"incline_user_login_histories"."created_at" <= ?', Time.now - max_months.months).delete_all
    end

  end
end