require 'active_support/logger'
require 'incline/json_log_formatter'

module Incline
  ##
  # Overrides the default formatter for the base logger.
  class JsonLogger < ::ActiveSupport::Logger
  
    ##
    # Sets the formatter to Incline::JsonLogFormatter.
    def initialize(*args)
      super
      @formatter = ::Incline::JsonLogFormatter.new
    end
    
  end
end
