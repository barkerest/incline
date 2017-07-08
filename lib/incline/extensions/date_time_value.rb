require 'incline/date_time_formats'
require 'incline/extensions/time_zone_converter'
require 'active_record'

module Incline::Extensions

  ##
  # Patches the ActiveRecord DateTime value to accept more date formats.
  #
  # Specifically this will allow ActiveRecord models to receive dates in US format or ISO format.
  module DateTimeValue

    ##
    # Patches the ActiveRecord DateTime value type.
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

                hour = match['HOUR'].to_s.to_i
                minute = match['MINUTE'].to_s.to_i
                second = match['SECOND'].to_s.to_i

                # make sure the fraction is 6 chars in length, then convert to microseconds.
                micros = match['FRACTION'].to_s[0...6].ljust(6,'0').to_i

                if match.names.include?('AMPM')
                  if match['AMPM'].to_s.upcase == 'P' && hour < 12
                    hour += 12
                  elsif match['AMPM'].to_s.upcase == 'A' && hour == 12
                    hour = 0
                  end
                end

                raise 'Invalid time (hour must be 0 to 24).' unless (0..24) === hour
                raise 'Invalid time (minute must be 0 to 59).' unless (0...60) === minute
                raise 'Invalid time (second must be 0 to 59).' unless (0...60) === second
                raise 'Invalid time (minute and second must be 0 if hour is 24).' if hour == 24 && (minute != 0 || second != 0)

                if hour == 24
                  dt += 86400
                  year = dt.year
                  month = dt.month
                  mday = dt.mday
                  hour = 0
                end

                # compute the tz offset in seconds.
                offset =
                    if match.names.include?('TZ')
                      if match['TZ']
                        tz = match['TZ'].to_s.gsub(':','').upcase
                        if %w(Z +0000 -0000).include?(tz)
                          0
                        else
                          (tz[0] == '-' ? -1 : 1) * ((tz[1..2].to_i * 3600) + (tz[3..4].to_i * 60))
                        end
                      else
                        nil
                      end
                    else
                      nil
                    end

                # use the new_time method to honor the ActiveRecord::Base.default_timezone
                new_time(year, month, mday, hour, minute, second, micros, offset)
              else
                # use the fallback if it doesn't match our formats.
                fallback_string_to_time(string)
              end
            rescue
              Incline::Log::warn "Failed to parse #{string.inspect}: #{$!.message}"
              nil
            end

          elsif string.respond_to?(:to_time)
            begin
              string.to_time
            rescue
              Incline::Log::warn "Failed to convert #{string.inspect} to time: #{$!.message}"
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

ActiveRecord::Type::DateTime.include Incline::Extensions::DateTimeValue

