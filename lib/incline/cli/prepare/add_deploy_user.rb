
module Incline
  class CLI
    class Prepare
      
      private
      
      def add_deploy_user(shell)
        shell.with_stat('Adding deploy user') do
          # clean up first
          begin
            shell.sudo_exec "userdel -fr #{@options[:deploy_user]}"
          rescue
            # ignore
          end
          
          begin
            shell.sudo_exec "groupdel #{@options[:deploy_user]}"
          rescue
            # ignore
          end

          # recreate the user.
          shell.sudo_exec "useradd -mU -s /bin/bash #{@options[:deploy_user]}"
          shell.sudo_exec "printf \"#{@options[:deploy_password]}\\n#{@options[:deploy_password]}\\n\" | passwd #{@options[:deploy_user]}"

          # add the user's group to the admin user.
          shell.sudo_exec "usermod -G #{@options[:deploy_user]} -a #{@options[:admin_user]}"

          # set the permissions on the user's home directory.
          # it should be /home/deploy or some such, but let's not assume so.
          @options[:deploy_home] = shell.exec("eval echo \"~#{@options[:deploy_user]}\"").split("\n").first.strip
          shell.sudo_exec "chown #{@options[:deploy_user]}:#{@options[:deploy_user]} #{@options[:deploy_home]} && chmod 755 #{@options[:deploy_home]}"
        end
      end
      
    end
  end
end