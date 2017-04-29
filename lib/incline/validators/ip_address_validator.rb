require 'ipaddr'

module Incline
  ##
  # Validates a string contains a valid IP address.
  class IpAddressValidator < ActiveModel::EachValidator

    ##
    # Validates attributes to determine if the values contain valid IP addresses.
    #
    # Set the :no_mask option to restrict the IP address to singular addresses only.
    def validate_each(record, attribute, value)
      begin
        unless value.blank?
          IPAddr.new(value)
          if options[:no_mask]
            if value =~ /\//
              record.errors[attribute] << (options[:message] || 'must not contain a mask')
            end
          elsif options[:require_mask]
            unless value =~ /\//
              record.errors[attribute] << (options[:message] || 'must contain a mask')
            end
          end
        end
      rescue IPAddr::InvalidAddressError
        record.errors[attribute] << (options[:message] || 'is not a valid IP address')
      end
    end
  end

end