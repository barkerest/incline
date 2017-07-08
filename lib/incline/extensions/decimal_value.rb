require 'incline/number_formats'
require 'active_record'

module Incline::Extensions

  module DecimalValue

    def self.included(base)
      base.class_eval do
        private

        undef cast_value

        def cast_value(value)
          begin
            casted_value =
                case value
                  when ::Float
                    convert_float_to_big_decimal(value)
                  when ::String
                    # 1,234.56789e0
                    if value =~ Incline::NumberFormats::WITH_DELIMITERS
                      value = value.gsub(',', '')
                    end
                    if value =~ Incline::NumberFormats::WITHOUT_DELIMITERS
                      BigDecimal(value, precision.to_i)
                    else
                      nil
                    end
                  when ::Numeric
                    BigDecimal(value, precision.to_i)
                  else
                    if value.respond_to?(:to_d)
                      value.to_d
                    else
                      cast_value(value.to_s)
                    end
                end

            apply_scale(casted_value) if casted_value
          rescue
            Incline::Log::warn "Failed to parse #{value.inspect}: #{$!.message}"
            nil
          end
        end


      end
    end

  end

end

ActiveRecord::Type::Decimal.include Incline::Extensions::DecimalValue