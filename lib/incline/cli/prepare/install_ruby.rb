
module Incline
  class CLI
    class Prepare
      
      private
      
      def install_ruby(shell)
        shell.with_stat("Install Ruby #{@options[:ruby_version]}", 1024) do
          result = shell.exec('which rbenv').to_s.strip
          raise 'failed to install rbenv' if result == ''

          shell.exec "rbenv install -v #{@options[:ruby_version]}"
          shell.exec "rbenv global #{@options[:ruby_version]}"

          result = shell.exec('which ruby').to_s.partition("\n")[0].strip
          raise 'ruby not where expected' unless result == shell.home_path + '/.rbenv/shims/ruby' || result == '~/.rbenv/shims/ruby'

          shell.exec "echo 'gem: --no-ri --no-rdoc' > ~/.gemrc"
          shell.exec 'gem install bundler'
          shell.exec 'rbenv rehash'
        end
      end
      
    end
  end
end