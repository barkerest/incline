module Incline

  ##
  # This class represents an application user.
  class User < ActiveRecord::Base

    ANONYMOUS_EMAIL = 'anonymous@server.local'

    has_many :login_histories

    before_save :downcase_email
    before_create :create_activation_digest

    attr_accessor :recaptcha

    attr_accessor :remember_token
    attr_accessor :activation_token
    attr_accessor :reset_token

    has_secure_password

    validates :name,
              presence: true,
              length: { maximum: 100 }

    validates :email,
              presence: true,
              length: { maximum: 250 },
              uniqueness: { case_sensitive: false },
              'incline/email' => true

    validates :password,
              presence: true,
              length: { minimum: 8 },
              allow_nil: true

    validates :disabled_by,
              length: { maximum: 250 }

    validates :disabled_reason,
              length: { maximum: 200 }

    validates :last_login_ip,
              length: { maximum: 64 },
              'incline/ip_address' => { no_mask: true }

    validates :password_digest,
              presence: true,
              length: { maximum: 100 }

    validates :activation_digest,
              :remember_digest,
              :reset_digest,
              length: { maximum: 100 }

    validates :recaptcha,
              'incline/recaptcha' => true


    ##
    # Gets all known users.
    scope :known, ->{ where.not(email: ANONYMOUS_EMAIL) }

    ##
    # Gets all of the currently enabled users.
    scope :enabled, ->{ where(enabled: true, activated: true) }

    ##
    # Sorts the users by name.
    scope :sorted, ->{ order(name: :asc) }

    ##
    # Gets the email address in a partially obfuscated fashion.
    def partial_email
      @partial_email ||=
          begin
            uid,_,domain = email.partition('@')
            if uid.length < 4
              uid = '*' * uid.length
            elsif uid.length < 8
              uid = uid[0..2] + ('*' * (uid.length - 3))
            else
              uid = uid[0..2] + ('*' * (uid.length - 6)) + uid[-3..-1]
            end
            "#{uid}@#{domain}"
          end
    end

    ##
    # Gets the email formatted with the name.
    def formatted_email
      "#{name} <#{email}>"
    end

    ##
    # Is this user a system administrator?
    def system_admin?
      enabled && system_admin
    end

    ##
    # Generates a remember token and saves the digest to the user model.
    def remember
      self.remember_token = Incline::User::new_token
      update_attribute(:remember_digest, Incline::User::digest(self.remember_token))
    end

    ##
    # Removes the remember digest from the user model.
    def forget
      update_attribute(:remember_digest, nil)
    end

    ##
    # Determines if the supplied token digests to the stored digest in the user model.
    def authenticated?(attribute, token)
      return false unless respond_to?("#{attribute}_digest")
      digest = send("#{attribute}_digest")
      return false if digest.blank?
      BCrypt::Password.new(digest).is_password?(token)
    end

    ##
    # Disables the user.
    #
    # The +other_user+ is required, cannot be the current user, and must be a system administrator.
    # The +reason+ is technically optional, but should be provided.
    def disable(other_user, reason)
      return false unless other_user&.system_admin?
      return false if other_user == self

      update_columns(
          disabled_by: other_user.email,
          disabled_at: Time.zone.now,
          disabled_reason: reason,
          enabled: false
      )
    end

    ##
    # Enables the user and removes any previous disable information.
    def enable
      update_columns(
          disabled_by: nil,
          disabled_at: nil,
          disabled_reason: nil,
          enabled: true
      )
    end

    ##
    # Marks the user as activated and removes the activation digest from the user model.
    def activate
      update_columns(
          activated: true,
          activated_at: Time.zone.now,
          activation_digest: nil
      )
    end

    ##
    # Sends the activation email to the user.
    def send_activation_email(client_ip = '0.0.0.0')
      Incline::UserMailer.account_activation(user: self, client_ip: client_ip).deliver_now
    end

    ##
    # Creates a reset token and stores the digest to the user model.
    def create_reset_digest
      self.reset_token = Incline::User::new_token
      update_columns(
          reset_digest: Incline::User::digest(reset_token),
          reset_sent_at: Time.zone.now
      )
    end

    ##
    # Was the password reset requested more than 2 hours ago?
    def password_reset_expired?
      reset_sent_at.nil? || reset_sent_at < 2.hours.ago
    end

    ##
    # Is this the anonymous user?
    def anonymous?
      email == ANONYMOUS_EMAIL
    end

    ##
    # Sends the password reset email to the user.
    def send_password_reset_email(client_ip = '0.0.0.0')
      Incline::UserMailer.password_reset(user: self, client_ip: client_ip).deliver_now
    end

    ##
    # Sends a missing account message when a user requests a password reset.
    def self.send_missing_reset_email(email, client_ip = '0.0.0.0')
      Incline::UserMailer::invalid_password_reset(email: email, client_ip: client_ip).deliver_now
    end

    ##
    # Sends a disabled account message when a user requests a password reset.
    def self.send_disabled_reset_email(email, client_ip = '0.0.0.0')
      Incline::UserMailer::invalid_password_reset(email: email, message: 'The account attached to this email address has been disabled.', client_ip: client_ip).deliver_now
    end

    ##
    # Sends a non-activated account message when a user requests a password reset.
    def self.send_inactive_reset_email(email, client_ip = '0.0.0.0')
      Incline::UserMailer::invalid_password_reset(email: email, message: 'The account attached to this email has not yet been activated.', client_ip: client_ip).deliver_now
    end

    ##
    # Returns a hash digest of the given string.
    def self.digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    ##
    # Generates a new random token in (url safe) base64.
    def self.new_token
      SecureRandom.urlsafe_base64(32)
    end

    ##
    # Generates the necessary system administrator account.
    #
    # When the database is initially seeded, the only user is the system administrator.
    #
    # The absolute default is **admin@barkerest.com** with a password of **Password1**.
    # These values will be used if they are not overridden for the current environment.
    #
    # You can override this by setting the +default_admin+ property in "config/secrets.yml".
    #
    #     # config/secrets.yml
    #     development:
    #       default_admin:
    #         email: admin@barkerest.com
    #         password: Password1
    #
    # Regardless of whether you use the absolute defaults or create your own, you will want
    # to change the password on first login.
    #
    def self.ensure_admin_exists!
      unless where(system_admin: true, enabled: true).count > 0

        msg = "Creating/reactivating default administrator...\n"
        if Rails.application.running?
          Rails.logger.info msg
        else
          print msg
        end

        def_adm = (Rails.application.secrets[:default_admin] || {}).symbolize_keys

        def_adm_email = def_adm[:email] || 'admin@barkerest.com'
        def_adm_pass = def_adm[:password] || 'Password1'

        user = User
                   .where(
                       email: def_adm_email
                   )
                   .first_or_create!(
                       name: 'Default Administrator',
                       email: def_adm_email,
                       password: def_adm_pass,
                       password_confirmation: def_adm_pass,
                       enabled: true,
                       system_admin: true,
                       activated: true,
                       activated_at: Time.zone.now
                   )

        unless user.enabled? && user.system_admin?
          user.password = def_adm_pass
          user.password_confirmation = def_adm_pass
          user.enabled = true
          user.system_admin = true
          user.activated = true
          user.activated_at = Time.zone.now
          user.save!
        end
      end
    end

    ##
    # Gets a generic anonymous user.
    def self.anonymous
      @anonymous = nil if Rails.env.test? # always start fresh in test environment.
      @anonymous ||=
          begin
            pwd = new_token
            where(email: ANONYMOUS_EMAIL)
                .first_or_create(
                    email: ANONYMOUS_EMAIL,
                    name: 'Anonymous',
                    enabled: false,
                    activated: true,
                    activated_at: Time.zone.now,
                    password: pwd,
                    password_confirmation: pwd
                )
          end
    end


    private

    def downcase_email
      email.downcase!
    end

    def create_activation_digest
      self.activation_token = Incline::User::new_token
      self.activation_digest = Incline::User::digest(activation_token)
    end

  end
end
