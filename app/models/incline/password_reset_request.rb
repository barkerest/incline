
module Incline
  class PasswordResetRequest
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :email
    attr_accessor :recaptcha

    validates :email, presence: true, 'incline/email' => true
    validates :recaptcha, 'incline/recaptcha' => true
  end

end
