
module Incline
  ##
  # Patches the ActiveRecord Integer type to be able to accept more numbers.
  #
  # Specifically this will allow comma delimited numbers to be provided to active record models.
  module IntegerValueExtensions

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
                if value =~ /\A[+-]?(0|[1-9][0-9]{0,2}(,[0-9]{3})*)(\.[0-9]*)?\z/
                  value = value.gsub(',', '')
                end
                if value =~ /\A[+-]?([0-9]+)(\.[0-9]*)?\z/
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
            Incline::Log::warn "Failed to parse #{value.inspect}."
            nil
          end
        end

      end
    end

  end
end

ActiveRecord::Type::Integer.include Incline::IntegerValueExtensions
