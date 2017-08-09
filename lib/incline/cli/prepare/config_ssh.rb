
module Incline
  class CLI
    class Prepare
      
      private
      
      def config_ssh(shell)
        pa_rex = /#\s*PubkeyAuthentication\s+[^\n]*\n/
        rl_rex = /#\s*PermitRootLogin\s+[^\n]*\n/

        shell.with_stat('Configuring SSH') do
          shell.sudo_exec "cp -f /etc/ssh/sshd_config #{shell.home_path}/tmp_sshd_conf"
          contents = shell.read_file("#{shell.home_path}/tmp_sshd_conf")
          new_contents = contents.gsub(pa_rex, "PubkeyAuthentication yes\n").gsub(rl_rex, "PermitRootLogin no\n")
          if new_contents != contents
            shell.write_file "#{shell.home_path}/tmp_sshd_conf", new_contents
            shell.sudo_exec "chown root:root #{shell.home_path}/tmp_sshd_conf"
            shell.sudo_exec "chmod 600 #{shell.home_path}/tmp_sshd_conf"
            shell.sudo_exec "mv -f #{shell.home_path}/tmp_sshd_conf /etc/ssh/sshd_config"
            
            begin
              shell.sudo_exec 'systemctl restart sshd.service'
            rescue
              # ignore any errors from the SSH restart.
            end
          end
        end
      end
      
    end
  end
end
