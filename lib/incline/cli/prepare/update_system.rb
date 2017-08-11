
module Incline
  class CLI
    class Prepare
      
      private
      
      def update_system(shell)
        shell.sudo_stat_exec 'Retrieving updates', 'apt-get -q update'
        shell.sudo_stat_exec 'Updating system', 'DEBIAN_FRONTEND=noninteractive apt-get -y -q upgrade'
        shell.sudo_stat_exec 'Updating kernel', 'DEBIAN_FRONTEND=noninteractive apt-get -y -q install linux-generic linux-headers-generic linux-image-generic'
      end
      
    end
  end
end