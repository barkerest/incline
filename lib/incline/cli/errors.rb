module Incline
  class CLI

    class CliError < ::RuntimeError; end
    class UsageError < CliError
      attr_accessor :command
      def initialize(msg, command = nil)
        super msg
        self.command = command
      end
      
    end

  end
end