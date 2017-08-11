
module Incline
  class CLI
    class Prepare
      
      private
      
      def install_db(shell)
        shell.with_stat('Installing MariaDB') do
          shell.sudo_exec 'debconf-set-selections <<< \'mariadb-server mysql-server/root_password password \''
          shell.sudo_exec 'debconf-set-selections <<< \'mariadb-server mysql-server/root_password_again password \''
          shell.apt_get 'install mariadb-server mariadb-client libmysqlclient-dev'
          shell.sudo_exec_ignore_code 'systemctl stop mysql.service'
          shell.sudo_exec 'systemctl start mysql.service'
          shell.sudo_exec 'systemctl enable mysql.service'
        end
      end
      
    end
  end
end