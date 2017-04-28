module Incline

  ##
  # Defines or overrides few string helper methods.
  module StringExtensions

    ##
    # Converts a hex string into a byte string.
    #
    # Whitespace in the string is ignored.
    # The string must only contain characters valid for hex (ie - 0-9, A-F, a-f).
    # The string must contain an even number of characters since each character only represents half a byte.
    def to_byte_string
      ret = self.gsub(/\s+/,'')
      raise 'Hex string must have even number of characters.' unless ret.size % 2 == 0
      raise 'Hex string must only contain 0-9 and A-F characters.' if ret =~ /[^0-9a-fA-F]/
      [ret].pack('H*').force_encoding('ascii-8bit')
    end

    ##
    # Converts a binary string into a hex string.
    #
    # The +grouping+ parameter can be set to true or an integer value specifying how many chars you want in
    # each group.  If true or less than 1, then characters are put into groups of 2.
    def to_hex_string(grouping = false)
      ret = self.unpack('H*').first
      if grouping
        if grouping.is_a?(Integer) && grouping > 0
          ret.gsub(/(#{'.' * grouping})/,'\1 ').rstrip
        else
          ret.gsub(/(..)/,'\1 ').rstrip
        end
      else
        ret
      end
    end

  end
end

String.include Incline::StringExtensions