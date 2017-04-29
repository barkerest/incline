module Incline

  ##
  # Adds the +object_pointer+ method to all objects.
  module ObjectExtensions

    ##
    # Gets the object_id formatted in hexadecimal with a leading '0x'.
    def object_pointer
      '0x' + self.object_id.to_s(16).rjust(12,'0').downcase
    end

  end
end

Object.include Incline::ObjectExtensions