
module Incline

  ##
  # Patches the ActiveRecord Float value type to accept more numbers.
  #
  # Specifically this will allow comma delimited numbers to be provided to active record models.
  module FloatValueExtensions

    ##
    # Patches the ActiveRecord Float value type.
    def self.included(base)

      base.class_eval do
        private

        undef cast_value

        def cast_value(value)
          begin
            case value
              when true
                1.0
              when false
                0.0
              when ::String
                # 1,234.56789
                if value =~ /\A[+-]?(0|[1-9][0-9]{0,2}(,[0-9]{3})*)(\.[0-9]*)?\z/
                  value = value.gsub(',', '')
                end
                if value =~ /\A[+-]?([0-9]+)(\.[0-9]*)?\z/
                  value.to_f
                else
                  nil
                end
              else
                if value.respond_to?(:to_f)
                  value.to_f
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

ActiveRecord::Type::Float.include Incline::FloatValueExtensions