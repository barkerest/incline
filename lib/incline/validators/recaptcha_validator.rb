
module Incline
  ##
  # Validates a reCAPTCHA attribute.
  class RecaptchaValidator < ActiveModel::EachValidator

    ##
    # Validates a reCAPTCHA attribute.
    #
    # The value of the attribute should be a hash with two keys: :response, :remote_ip
    def validate_each(record, attribute, value)
      unless Incline::Recaptcha::verify(response: value[:response], remote_ip: value[:remote_ip])
        record.errors[:base] << (options[:message] || 'requires reCAPTCHA challenge to be completed')
      end
    end

  end
end