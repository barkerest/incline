
module Incline
  ##
  # Validates a string to ensure it contains a valid email address.
  #
  #   validates :email_address, 'incline/email' => true
  #
  class EmailValidator < ActiveModel::EachValidator

    INTERNAL_DOM_REGEX = '[a-z\d]+(?:-+[a-z\d]+)*(?:\.[a-z\d]+(?:-+[a-z\d]+)*)*\.[a-z]+'
    private_constant :INTERNAL_DOM_REGEX

    ##
    # This regular expression should validate 99.9% of common email addresses.
    #
    # There are some weird rules that it doesn't account for, but they should be rare.
    #
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@#{INTERNAL_DOM_REGEX}\z/i

    ##
    # This regular expression should validate any domain.
    VALID_DOMAIN_REGEX = /\A#{INTERNAL_DOM_REGEX}\z/i


    ##
    # Validates attributes to determine if they contain valid email addresses.
    #
    # Does not perform an in depth check, but does verify that the format is valid.
    def validate_each(record, attribute, value)
      unless value.blank?
        record.errors[attribute] << (options[:message] || 'is not a valid email address') unless value =~ VALID_EMAIL_REGEX
      end
    end

    ##
    # Validates that an email address is valid based on format.
    def self.valid?(email)
      return false if email.blank?
      !!(email =~ VALID_EMAIL_REGEX)
    end

  end
end


