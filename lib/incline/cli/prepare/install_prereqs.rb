
module Incline
  class CLI
    class Prepare
      private
      
      def install_prereqs(shell)
        shell.with_stat('Installing prerequisites') do
          shell.sudo_exec 'apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev'
        end
      end
      
    end
  end
end