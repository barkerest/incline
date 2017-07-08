require 'incline/number_formats'
require 'active_record'

module Incline::Extensions
  ##
  # Patches the ActiveRecord Integer type to be able to accept more numbers.
  #
  # Specifically this will allow comma delimited numbers to be provided to active record models.
  module IntegerValue

    ##
    # Patches the ActiveRecord Integer type.
    def self.included(base) #:nodoc:
      base.class_eval do

        private

        undef cast_value

        def cast_value(value)
          begin
            case value
              when true then 1
              when false then 0
              when ::String
                # 1,234.56789
                if value =~ Incline::NumberFormats::WITH_DELIMITERS
                  value = value.gsub(',', '')
                end
                if value =~ Incline::NumberFormats::WITHOUT_DELIMITERS
                  value.to_i
                else
                  nil
                end
              else
                if value.respond_to?(:to_i)
                  value.to_i
                else
                  nil
                end
            end
          rescue
            Incline::Log::warn "Failed to parse #{value.inspect}: #{$!.message}"
            nil
          end
        end

      end
    end

  end
end

ActiveRecord::Type::Integer.include Incline::Extensions::IntegerValue
