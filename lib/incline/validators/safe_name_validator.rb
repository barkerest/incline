
module Incline
  ##
  # Validates a string value to ensure it starts with a letter and contains only letters, numbers, and underscores.
  class SafeNameValidator < ActiveModel::EachValidator

    ##
    # Validates a string to ensure it starts with a letter and contains only letters, numbers, and underscores.
    VALID_MASK = /\A[a-z][a-z0-9_]*\z/i

    ##
    # The default message when this validation fails.
    DEFAULT_MESSAGE = 'must start with a letter and only contain letters, numbers, and underscores'

    ##
    # Validates attributes to determine if the values match the requirements of a safe name.
    def validate_each(record, attribute, value)
      unless value.blank?
        record.errors[attribute] << (options[:message] || DEFAULT_MESSAGE) unless value =~ VALID_MASK
      end
    end

  end
end