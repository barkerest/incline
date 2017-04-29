
module Incline
  ##
  # Validates a string value to ensure it is a safe name.
  #
  # A safe name is one that only contains letters, numbers, and underscore.
  # It must also start with a letter and cannot end with an underscore.
  class SafeNameValidator < ActiveModel::EachValidator

    ##
    # Validates a string to ensure it is a safe name.
    VALID_MASK = /\A[a-z](?:_*[a-z0-9]+)*\z/i

    ##
    # Validates attributes to determine if the values match the requirements of a safe name.
    def validate_each(record, attribute, value)
      unless value.blank?
        unless value =~ VALID_MASK
          if value =~ /\A[^a-z]/i
            record.errors[attribute] << (options[:message] || 'must start with a letter')
          elsif value =~ /_\z/
            record.errors[attribute] << (options[:message] || 'must not end with an underscore')
          else
            record.errors[attribute] << (options[:message] || 'must contain only letters, numbers, and underscore')
          end
        end
      end
    end

  end
end