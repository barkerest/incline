
module Incline
  class CLI
    class Prepare
      
      private
      
      def install_passenger(shell)
        distros = {
            '12.04' => 'precise',
            '12.10' => 'quantal',
            '13.04' => 'raring',
            '13.10' => 'saucy',
            '14.04' => 'trusty',
            '14.10' => 'utopic',
            '15.04' => 'vivid',
            '15.10' => 'wily',
            '16.04' => 'xenial',
            '16.10' => 'yakkety',
            '17.04' => 'zesty'
        }

        distro = distros[host_info['VERSION_ID']]
        shell.with_stat('Installing Phusion Passenger') do
          shell.sudo_exec 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7'
          shell.apt_get 'install apt-transport-https ca-certificates'
          shell.sudo_exec "echo deb https://oss-binaries.phusionpassenger.com/apt/passenger #{distro} main > /etc/apt/sources.list.d/passenger.list"
          shell.apt_get 'update'
          shell.apt_get 'install nginx-extras passenger'
          shell.sudo_exec_ignore_code 'systemctl stop nginx'
          shell.sudo_exec 'systemctl start nginx'
          shell.sudo_exec 'systemctl enable nginx'
        end
      end
    end
  end
end