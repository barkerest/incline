
module Incline
  ##
  # Validates a string to ensure it contains a valid email address.
  class EmailValidator < ActiveModel::EachValidator

    ##
    # This regular expression should validate 99.9% of common email addresses.
    #
    # There are some weird rules that it doesn't account for, but they should be rare.
    #
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d]+)*\.[a-z]+\z/i

    ##
    # Validates attributes to determine if they contain valid email addresses.
    def validate_each(record, attribute, value)
      unless value.blank?
        record.errors[attribute] << (options[:message] || 'is not a valid email address') unless value =~ VALID_EMAIL_REGEX
      end
    end

  end
end
