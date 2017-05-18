
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
      return if value.blank?

      # Make sure the response only gets processed once.
      return if value == :verified

      # Automatically skip validation if paused.
      return if Incline::Recaptcha::paused?

      # If the user form includes the recaptcha field, then something will come in
      # and then we want to check it.
      remote_ip, _, response = value.partition('|')
      if remote_ip.blank? || response.blank?
        record.errors[:base] << (options[:message] || 'Requires reCAPTCHA challenge to be completed')
      else
        if Incline::Recaptcha::verify(response: response, remote_ip: remote_ip)
          record.send "#{attribute}=", :verified
        else
          record.errors[:base] << (options[:message] || 'Invalid response from reCAPTCHA challenge')
        end
      end

    end

  end
end