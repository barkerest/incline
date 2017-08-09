
module Incline
  class CLI
    class Prepare
      
      private
      
      def update_system(shell)
        shell.sudo_stat_exec 'Retrieving updates', 'apt-get update'
        shell.sudo_stat_exec 'Updating system', 'apt-get -y upgrade'
        shell.sudo_stat_exec 'Updating kernel', 'apt-get -y install linux-generic linux-headers-generic linux-image-generic'
      end
      
    end
  end
end