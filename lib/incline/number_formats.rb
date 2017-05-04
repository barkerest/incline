module Incline
  module NumberFormats

    ##
    # Verifies a number with comma delimiters included.
    #
    # 1,234,567.89e0
    WITH_DELIMITERS = /\A[+-]?(0|[1-9][0-9]{0,2}(,[0-9]{3})*)(\.[0-9]*)?(e\d+)?\z/i

    ##
    # Verifies a number without comma delimiters included.
    #
    # 1234567.89e0
    WITHOUT_DELIMITERS = /\A[+-]?([0-9]+)(\.[0-9]*)?(e\d+)?\z/i

  end
end