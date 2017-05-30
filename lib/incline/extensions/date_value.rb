require 'incline/date_time_formats'
require 'incline/extensions/time_zone_converter'

module Incline::Extensions

  ##
  # Patches the ActiveRecord Date value to accept more date formats.
  #
  # Specifically this will allow ActiveRecord models to receive dates in US format or ISO format.
  module DateValue

    ##
    # Patches the ActiveRecord Date value type.
    def self.included(base)
      base.class_eval do

        private

        undef cast_value

        def cast_value(string)
          return nil if string.blank?
          return string if string.is_a?(::Time)

          if string.is_a?(::String)

            begin
              # if it matches either of our formats, we can try using it.
              if (match = (Incline::DateTimeFormats::US_DATE_FORMAT.match(string) || Incline::DateTimeFormats::ALMOST_ISO_DATE_FORMAT.match(string)))

                year = match['YEAR'].to_s.to_i
                year += 2000 if year < 50
                year += 1900 if year < 100
                month = match['MONTH'].to_s.to_i
                mday = match['DAY'].to_s.to_i

                # ensure the date portion is valid.
                dt =
                    begin
                      Time.utc(year, month, mday)
                    rescue
                      raise "Invalid date (#{$!.message})."
                    end

                raise 'Invalid date (day of month is invalid for month).' unless dt.year == year && dt.month == month && dt.mday == mday

                ::Date.new(year, month, mday)
              else
                # use the fallback if it doesn't match our formats.
                fallback_string_to_date(string)
              end
            rescue
              Incline::Log::warn "Failed to parse #{string.inspect}: #{$!.message}"
              nil
            end

          elsif string.respond_to?(:to_date)
            begin
              string.to_date
            rescue
              Incline::Log::warn "Failed to convert #{string.inspect} to date: #{$!.message}"
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

ActiveRecord::Type::Date.include Incline::Extensions::DateValue

