
module Incline
  class CLI
    class Prepare
      
      private
      
      def install_rbenv(shell)
        
        shell.with_stat('Installing rbenv') do
          shell.exec "git clone https://github.com/rbenv/rbenv.git #{shell.home_path}/.rbenv"
          shell.exec "git clone https://github.com/rbenv/ruby-build.git #{shell.home_path}/.rbenv/plugins/ruby-build"

          bashrc = shell.read_file(shell.home_path + '/.bashrc') || ''
          lines = bashrc.split("\n")
          first_line = nil
          lines.each_with_index do |line,index|
            if line.strip[0] != '#'
              first_line = index
              break
            end
          end
          first_line ||= lines.count
          lines.insert first_line, <<-EORC

# Initialize rbenv and ruby.
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
eval "$(rbenv init -)"

          EORC

          bashrc = lines.join("\n")
          shell.write_file(shell.home_path + '/.bashrc', bashrc)
        end
        
      end
    end
  end
end