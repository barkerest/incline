
module Incline
  class CLI

    ##
    # Defines the 'usage' command for the CLI.
    class Usage

      ##
      # Creates a new 'usage' command for the CLI.
      def initialize

      end

      ##
      # Shows usage information for the application.
      def run

        commands = Incline::CLI::valid_commands.sort{|a,b| a[0] <=> b[0]}

        msg = ANSI.ansi(:bold) { "Usage: #{$PROGRAM_NAME} command <arguments>" }
        msg += "\nValid Commands:\n"

        commands.each do |(name,klass,params)|
          comment = get_run_comment(klass)
          comment = "(No description)" if comment.to_s.strip == ''
          comment = '    ' + comment.gsub("\n", "\n    ")
          msg += "  #{name}"
          pend = ''
          params.each do |t,p|
            msg += ' '
            if t == :req
              msg += p.to_s
            elsif t == :opt
              msg += '[' + p.to_s
              pend += ']'
            else
              msg += '<...>'
            end
          end
          msg += "\n" + comment + "\n"
        end

        STDOUT.print msg
        msg
      end

      private

      def get_run_comment(klass)
        meth = klass.instance_method(:run)
        return '' unless meth
        file,line_num = meth.source_location
        return '' unless file && line_num
        return '' unless File.exist?(file)

        source_lines = File.read(file).gsub("\r\n", "\n").split("\n")

        comments = []

        # line_num is 1 based so we need to subtract 1 to get the line with the method definition
        # then we subtract 1 again to get the first line before the method definition.
        line_num -= 2

        while line_num >= 0 && source_lines[line_num] =~ /\A(?:\s*)(?:#(?:\s(.*))?)?\z/
          line = $1.to_s
          comments << line
          line_num -= 1
        end

        comments.reverse.join("\n")
      end

    end

  end
end