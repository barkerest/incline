module Incline
  class CLI

    class CliError < ::RuntimeError; end
    class UsageError < CliError; end

  end
end