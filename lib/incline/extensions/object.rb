module Incline::Extensions

  ##
  # Adds the +object_pointer+ method to all objects.
  module Object

    ##
    # Gets the object_id formatted in hexadecimal with a leading '0x'.
    def object_pointer
      '0x' + self.object_id.to_s(16).rjust(12,'0').downcase
    end

    ##
    # Converts this object into a boolean value.
    #
    # The +true+ value returns true, as do the :true, :yes, and :on symbols.
    # Any numeric not equal to 0 returns true.
    # And the strings of 'true', 't', 'yes', 'y', 'on', and '1' (case-insensitive) return true.
    # Everything else will return false, including +nil+.
    #
    # This obviously differs from the Ruby behavior that only nil and false evaluate to false.
    # This is not meant to replace that behavior, it was actually meant to enable simple usage of
    # other values commonly used to the represent true and false (eg - 0 and 1).
    def to_bool
      is_a?(::TrueClass) || self == :true || self == :yes || self == :on
    end

  end
end

Object.include Incline::Extensions::Object