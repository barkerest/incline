
module Incline
  class CLI
    class Prepare
      
      private
      
      def restart_nginx(shell)
        shell.with_stat('Restarting nginx') do
          # test the configuration.
          shell.sudo_exec('nginx -t')

          # stop the service.
          begin
            shell.sudo_exec 'systemctl stop nginx.service'
          rescue
            # ignore service stoppage errors.
          end

          # start the service.
          shell.sudo_exec 'systemctl start nginx.service'
        end
      end
      
    end
  end
end