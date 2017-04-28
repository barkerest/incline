module Incline
  ##
  # Adds to_human to numeric types (floats and integers).
  module NumericExtensions

    ##
    # The short scale for humanizing a number.
    SHORT_SCALE =
        [
            [ 1E39, 'duodecillion' ],
            [ 1E36, 'undecillion' ],
            [ 1E33, 'decillion' ],
            [ 1E30, 'nonillion' ],
            [ 1E27, 'octilillion' ],
            [ 1E24, 'septillion' ],
            [ 1E21, 'sextillion' ],
            [ 1E18, 'quintillion' ],
            [ 1E15, 'quadrillion' ],
            [ 1E12, 'trillion' ],
            [ 1E9, 'billion' ],
            [ 1E6, 'million' ]
        ]

    ##
    # Formats the number using the short scale for any number over 1 million.
    def to_human
      Incline::NumericExtensions::SHORT_SCALE.each do |(num,label)|
        if self > num
          return "%.2f #{label}" % (self / num)
        end
      end
      to_s
    end

  end
end

Numeric.include Incline::NumericExtensions