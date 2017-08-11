
module Incline
  class CLI
    class Prepare
      
      private
      
      def install_db(shell)
        shell.with_stat('Installing MariaDB') do
          shell.sudo_exec 'debconf-set-selections <<< \'mariadb-server mysql-server/root_password password \''
          shell.sudo_exec 'debconf-set-selections <<< \'mariadb-server mysql-server/root_password_again password \''
          shell.sudo_exec 'DEBIAN_FRONTEND=noninteractive apt-get -y -q install mariadb-server mariadb-client libmysqlclient-dev'
          begin
            shell.sudo_exec 'systemctl stop mysql.service'
          rescue
            # don't propagate errors from the service stoppage.
          end
          shell.sudo_exec 'systemctl start mysql.service'
          shell.sudo_exec 'systemctl enable mysql.service'
        end
      end
      
    end
  end
end