
module Incline
  class CLI
    class Prepare
      
      private
      
      def update_system(shell)
        shell.with_stat('Retrieving updates') { shell.apt_get 'update' }
        shell.with_stat('Updating system') { shell.apt_get 'upgrade' }
        shell.with_stat('Updating kernel') { shell.apt_get 'install linux-generic linux-headers-generic linux-image-generic' }
      end
      
    end
  end
end