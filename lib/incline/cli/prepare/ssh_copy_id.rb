
module Incline
  class CLI
    class Prepare
      private
      
      def ssh_copy_id(shell)
        my_id_file = File.expand_path('~/.ssh/rsa_id.pub')
        if File.exist?(my_id_file)
          my_id = File.read(my_id_file)
          shell.with_stat('Enabling public key authentication') do
            
            shell.exec 'if [ ! -d ~/.ssh ]; then mkdir ~/.ssh; fi'
            shell.exec 'chmod 700 ~/.ssh'
            
            contents = shell.read_file("#{shell.home_path}/.ssh/authorized_keys")
            if contents
              unless contents.split("\n").find{|k| k.to_s.strip == my_id.strip}
                contents += "\n" unless contents[-1] == "\n"
                contents += my_id.strip + "\n"
                shell.write_file("#{shell.home_path}/.ssh/authorized_keys", contents)
              end
            else
              shell.write_file("#{shell.home_path}/.ssh/authorized_keys", my_id + "\n")
            end
            
          end
        end
      end
    end
  end
end