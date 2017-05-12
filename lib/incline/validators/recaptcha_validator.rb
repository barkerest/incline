
module Incline
  ##
  # Validates a reCAPTCHA attribute.
  class RecaptchaValidator < ActiveModel::EachValidator

    ##
    # Validates a reCAPTCHA attribute.
    #
    # The value of the attribute should be a hash with two keys: :response, :remote_ip
    def validate_each(record, attribute, value)
      # Do NOT raise an error if nil.
      # If the user form includes the recaptcha field, then something will come in
      # and then we want to check it.
      # If the user form does not include the recaptcha field, then we don't need to check it.
      if value.is_a?(Hash)
        unless Incline::Recaptcha::verify(response: value[:response], remote_ip: value[:remote_ip])
          record.errors[:base] << (options[:message] || 'requires reCAPTCHA challenge to be completed')
        end
      end
    end

  end
end