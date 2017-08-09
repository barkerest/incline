module Incline
  class CLI
    class Prepare
      
      private
      
      def install_rails(shell)
        shell.with_stat("Installing Rails #{@options[:rails_version]}") do
          shell.exec "gem install rails -v #{@options[:rails_version]}"
          shell.exec 'rbenv rehash'
        end
      end
    end
  end
end