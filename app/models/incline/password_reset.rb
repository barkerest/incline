module Incline
  class PasswordReset
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :password
    attr_accessor :recaptcha

    validates :password, presence: true, length: { minimum: 8 }, confirmation: true
    validates :password_confirmation, presence: true
    validates :recaptcha, presence: true, 'incline/recaptcha' => true

  end
end