
module Incline
  class CLI

    ##
    # Defines the 'version' command for the CLI.
    class Version

      ##
      # Creates a new 'version' command for the CLI.
      def initialize

      end

      ##
      # Shows the version of the Incline library.
      def run
        STDOUT.puts "Incline v#{Incline::VERSION}"
      end

    end
  end
end