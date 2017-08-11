
module Incline
  class CLI
    class Prepare
      
      private
      
      def user_process_list(shell, user)
        shell.sudo_exec_ignore_code("pgrep -u #{@options[:deploy_user]}").to_s.split("\n").map(&:strip).reject{|s| s == ''}
      end
      
      def kill_processes(shell, user, signal)
        if user_process_list(shell, user).any?
          shell.sudo_exec_ignore_code "pkill -#{signal} -u #{user}"
          et = Time.now + 5
          while Time.now < et
            return true if user_process_list(shell, user).empty?
            sleep 1
          end
          user_process_list(shell,user).any?
        else
          true
        end
      end
      
      def add_deploy_user(shell)
        # clean up first
        unless shell.get_user_id(@options[:deploy_user]) == 0
          shell.with_stat('Removing previous deploy user') do
            unless kill_processes(shell, @options[:deploy_user], 'TERM')
              unless kill_processes(shell, @options[:deploy_user], 'KILL')
                raise CliError, "Failed to kill all processes owned by #{@options[:deploy_user]}."
              end
            end
            # remove crontab for user.
            shell.sudo_exec_ignore_code "crontab -u #{@options[:deploy_user]} -r"
            # remove at jobs for user.
            shell.sudo_exec_ignore_code "find /var/spool/cron/atjobs -name \"[^.]*\" -type f -user #{@options[:deploy_user]} -delete"
            # remove the user.
            shell.sudo_exec "userdel -r #{@options[:deploy_user]}"
            # remove the main user group.
            shell.sudo_exec_ignore_code "groupdel #{@options[:deploy_user]}"
          end
        end

        shell.with_stat('Adding deploy user') do
          # create the user.
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