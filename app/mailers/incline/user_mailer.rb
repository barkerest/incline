module Incline

  ##
  # This mailer is used for the account activation, password reset, and invalid password reset messages.
  #
  class UserMailer < ::Incline::ApplicationMailerBase

    ##
    # Sends the activation email to a new user.
    def account_activation(data = {})
      @data = {
          user: nil,
          client_ip: '0.0.0.0'
      }.merge(data || {})
      raise unless data[:user]
      mail to: data[:user].email, subject: 'Account activation'
    end

    ##
    # Sends the password reset email to an existing user.
    def password_reset(data = {})
      @data = {
          user: nil,
          client_ip: '0.0.0.0'
      }.merge(data || {})
      raise unless data[:user]
      mail to: data[:user].email, subject: 'Password reset request'
    end

    ##
    # Sends an invalid password reset attempt message to a user whether they exist or not.
    def invalid_password_reset(data = {})
      @data = {
          email: nil,
          message: 'This email address is not associated with an existing account.',
          client_ip: '0.0.0.0'
      }.merge(data || {})
      raise unless data[:email]
      mail to: data[:email], subject: 'Password reset request'
    end

  end

end