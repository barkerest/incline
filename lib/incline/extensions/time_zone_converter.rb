module Incline::Extensions
  ##
  # Patches the TimeZoneConverter to call super.
  module TimeZoneConverter

    ##
    # Patches the TimeZoneConverter to call super.
    def self.included(base)
      base.class_eval do

        undef type_cast_from_user

        def type_cast_from_user(value)
          if value.is_a?(Array)
            value.map { |v| type_cast_from_user(v) }
          else
            # Convert to time first.
            value = super

            # Then convert the time zone if necessary.
            if value.respond_to?(:in_time_zone)
              begin
                value.in_time_zone
              rescue ArgumentError
                nil
              end
            else
              nil
            end
          end
        end
      end
    end

  end
end

ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter.include Incline::Extensions::TimeZoneConverter
