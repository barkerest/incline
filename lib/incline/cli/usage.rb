
module Incline
  class CLI

    ##
    # Defines the 'usage' command for the CLI.
    class Usage

      ##
      # Creates a new 'usage' command for the CLI.
      def initialize(command = nil)
        @command = command ? command.to_s.downcase.to_sym : nil
      end

      ##
      # Shows usage information for the application.
      def run
        msg = nil
        
        if @command
          command = Incline::CLI::valid_commands.find{|c| c[0] == @command}
          if command
            msg = "Usage: #{$PROGRAM_NAME} #{command[0]}"
            pend = ''
            command[2].each do |t,p|
              msg += ' '
              if t == :req
                msg += p.to_s
              elsif t == :opt
                msg += '[' + p.to_s
                pend += ']'
              else
                msg += '<...>'
              end
              msg += pend
            end
            msg = ANSI.ansi(:bold) { msg }
            msg += "\n"
            comment = get_run_comment(command[1])
            comment = "(No additional information)" if comment.to_s.strip == ''
            comment = '    ' + comment.gsub("\n", "\n    ")
            msg += comment + "\n"
          end
        end
        
        unless msg
          commands = Incline::CLI::valid_commands.sort{|a,b| a[0] <=> b[0]}
          
          msg = ANSI.ansi(:bold) { "Usage: #{$PROGRAM_NAME} command <arguments>" }
          if @command
            msg += "\nInvalid Command: #{@command}\n"
          end
          msg += "\nValid Commands:\n"
          commands.each do |(name,klass,params)|
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
            msg += pend + "\n"
          end
          
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