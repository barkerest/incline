require 'bigdecimal'

module Incline
  ##
  # Adds to_human to numeric types (floats and integers).
  module NumericExtensions

    ##
    # The short scale for humanizing a number.
    SHORT_SCALE =
        [
            [ Integer('1'.ljust(40,'0')), 'duodecillion' ],
            [ Integer('1'.ljust(37,'0')), 'undecillion' ],
            [ Integer('1'.ljust(34,'0')), 'decillion' ],
            [ Integer('1'.ljust(31,'0')), 'nonillion' ],
            [ Integer('1'.ljust(28,'0')), 'octilillion' ],
            [ Integer('1'.ljust(25,'0')), 'septillion' ],
            [ Integer('1'.ljust(22,'0')), 'sextillion' ],
            [ Integer('1'.ljust(19,'0')), 'quintillion' ],
            [ Integer('1'.ljust(16,'0')), 'quadrillion' ],
            [ Integer('1'.ljust(13,'0')), 'trillion' ],
            [ Integer('1'.ljust(10,'0')), 'billion' ],
            [ Integer('1'.ljust(7,'0')), 'million' ],
            [ Integer('1'.ljust(4,'0')), 'thousand' ],
        ]

    ##
    # Formats the number using the short scale for any number over 1 million.
    def to_human
      Incline::NumericExtensions::SHORT_SCALE.each do |(num,label)|
        if self >= num
          s = ('%.2f' % (self.to_f / num)).gsub(/\.?0+\z/,'')
          return "#{s} #{label}"
        end
      end

      if self.is_a?(Rational)
        if self.denominator == 1
          return self.numerator.to_s
        end
        return self.to_s
      elsif self.is_a?(Integer)
        return self.to_s
      end

      ('%.2f' % self.to_f).gsub(/\.?0+\z/,'')
    end

  end
end

Numeric.include Incline::NumericExtensions