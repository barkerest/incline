require 'securerandom'
require 'json'
require 'shells'
require 'io/console'
require 'ansi/code'

require 'incline/cli/prepare/extend_shell'
require 'incline/cli/prepare/update_system'
require 'incline/cli/prepare/ssh_copy_id'
require 'incline/cli/prepare/config_ssh'
require 'incline/cli/prepare/install_prereqs'
require 'incline/cli/prepare/install_db'
require 'incline/cli/prepare/add_deploy_user'
require 'incline/cli/prepare/install_rbenv'
require 'incline/cli/prepare/install_ruby'
require 'incline/cli/prepare/install_rails'
require 'incline/cli/prepare/install_flytrap'
require 'incline/cli/prepare/install_passenger'
require 'incline/cli/prepare/config_passenger'
require 'incline/cli/prepare/create_nginx_utils'
require 'incline/cli/prepare/restart_nginx'

module Incline
  class CLI
    ##
    # Defines the 'prepare' command for the CLI.
    class Prepare

      ##
      # Creates a new 'prepare' command for the CLI.
      def initialize(host_name_or_ip, ssh_user, *options)
        @options = {
            port: 22,
            deploy_user: 'deploy',
            deploy_password: SecureRandom.urlsafe_base64(24),
            admin_password: '',
            ruby_version: '2.3.4',
            rails_version: '4.2.9'
        }
        @options[:host] = host_name_or_ip.to_s.strip

        raise UsageError.new("The 'host_name_or_ip' parameter is required.", 'prepare') if @options[:host] == ''

        if @options[:host] =~ /\A(?:\[[0-9a-f:]+\]|[a-z0-9]+(?:\.[a-z0-9]+)*):(?:\d+)\z/i
          h,_,p = @options[:host].rpartition(':')
          @options[:host] = h
          @options[:port] = p.to_i
        end

        @options[:admin_user] = ssh_user.to_s.strip

        raise UsageError.new("The 'ssh_user' parameter is required.", 'prepare') if @options[:admin_user] == ''

        while options.any?
          flag = options.delete_at(0)
          case flag
            when '--ssh-password'
              @options[:admin_password] = options.delete_at(0).to_s.strip
            when '--port'
              @options[:port] = options.delete_at(0).to_s.to_i
            when '--deploy-user'
              @options[:deploy_user] = options.delete_at(0).to_s.strip
              raise UsageError.new("The '--deploy-user' parameter requires a valid username.", 'prepare') unless @options[:deploy_user] =~ /\A[a-z][a-z0-9_]*\z/i
              raise UsageError.new("The '--deploy-user' parameter cannot match the 'ssh_user' parameter.", 'prepare') if @options[:deploy_user] == @options[:admin_user]
            when '--ruby-version'
              @options[:ruby_version] = options.delete_at(0).to_s.strip
              raise UsageError.new("The '--ruby-version' parameter must be at least 2.3.", 'prepare') if @options[:ruby_version].to_f < 2.3
            when '--rails-version'
              @options[:rails_version] = options.delete_at(0).to_s.strip
              raise UsageError.new("The '--rails-version' parameter must be at least 4.2.", 'prepare') if @options[:rails_version].to_f < 4.2

            # These options can be used to customize the self-signed certificate created initially.
            when '--ssl-country'
              @options[:ssl_country] = options.delete_at(0).to_s.strip
            when '--ssl-state', '--ssl-province'
              @options[:ssl_state] = options.delete_at(0).to_s.strip
            when '--ssl-location', '--ssl-city'
              @options[:ssl_location] = options.delete_at(0).to_s.strip
            when '--ssl-org'
              @options[:ssl_org] = options.delete_at(0).to_s.strip

            else
              raise UsageError.new("The '#{flag}' parameter is not recognized.", 'prepare')
          end
        end

        @options[:port] = 22 unless (1..65535).include?(@options[:port])
        if @options[:admin_password].to_s.strip == ''
          print 'Please enter the sudo password: '
          @options[:admin_password] = STDIN.noecho(&:gets).to_s.strip
          puts ''
          if @options[:admin_password].to_s.strip == ''
            puts 'WARNING: Sudo password is blank and script may fail because of this.'
          end
        end

        @options[:ssl_country] = 'US' if @options[:ssl_country].to_s == ''
        @options[:ssl_state] = 'Pennsylvania' if @options[:ssl_state].to_s == ''
        @options[:ssl_location] = 'Pittsburgh' if @options[:ssl_location].to_s == ''
        @options[:ssl_org] = 'WEB' if @options[:ssl_org].to_s == ''

      end

      ##
      # Prepares an Ubuntu server with NGINX and Passenger to run Rails applications.
      #
      # Set 'host_name_or_ip' to the DNS name or IP address for the host.
      # Set 'ssh_user' to the user name you want to access the host as.
      # This user must be able to run 'sudo' commands and must not be 'root'.
      #
      # You can provide a port value either appended to the host name or as a
      # separate argument using the '--port' option.
      # e.g. ssh.example.com:22 or --port 22
      #
      # If you are configured with key authentication to the host then you don't
      # need to provide an SSH password to connect.  However, this password is
      # also used to run sudo commands.  You can specify a password on the command
      # line by using the '--ssh-password' option.  If you do not, then the script
      # will prompt you for a "sudo" password to use.  You can leave this blank,
      # but the script will warn you that it may lead to failure.  Obviously, if
      # you are configured with NOPASSWD in the sudoers file, then you can safely
      # leave the password blank.
      #
      # By default, a deployment user named 'deploy' will be created on the host.
      # If a user by this name already exists, that user will be removed first.
      # This means that any data stored in the user profile will be destroyed by
      # the script prior to creating the new user. You can change the name of the
      # deployment user using the '--deploy-user' option.
      # e.g. --deploy_user bob
      #
      # The script will install 'rbenv' under the deploy user's account and then
      # install Ruby followed by Rails.  The default Ruby version installed is
      # 2.3.4 and the Rails version installed is 4.2.9.  To change these versions
      # use the '--ruby-version' and '--rails-version' options.  The Ruby version
      # must be at least 2.3 and the rails version must be at least 4.2.
      #
      def run
        # reset the host info.
        @host_info = nil

        admin_shell do |admin|
          # test the connection and sudo capabilities.
          admin.sudo_stat_exec 'Testing connection', 'ls -al /root'

          # retrieve the host info now that we are connected.
          @host_info = admin.host_info
          raise CliError, "Host OS (#{host_id}) is not supported." unless [ :ubuntu ].include?(host_id)

          # update the system and configure SSH.
          update_system admin
          ssh_copy_id(admin) unless @options[:admin_password] == ''
          config_ssh admin
        end
        # end the session and reconnect to take advantage of the SSH reset done at the end of config_ssh
        admin_shell do |admin|
          # install ruby prerequisites and mariadb.
          install_prereqs admin
          install_db admin

          # add the deploy user.
          add_deploy_user admin

          # log in as deploy user
          deploy_shell do |deploy|
            # enable key auth.
            ssh_copy_id deploy

            # install rbenv.
            install_rbenv deploy
          end

          # log out and then back in to load rbenv
          deploy_shell do |deploy|
            # install ruby & rails
            install_ruby deploy
            install_rails deploy

            # one more fun little addition, we'll add the flytrap app to catch path attacks.
            install_flytrap deploy
          end
          # done with the deploy user, so log out of that session.

          # install Phusion Passenger to the host and then configure it.
          install_passenger admin
          config_passenger admin

          # create a few helper utilities to test and reload the configuration.
          create_nginx_utils admin

          # then restart nginx.
          restart_nginx admin

          puts 'Testing nginx server...'
          admin.exec_ignore_code 'curl http://localhost/this-is-a-test'
          admin.exec "curl #{flytrap_path}"
        end

        puts ''
        puts ANSI.ansi(:bold, :white) { 'Host preparation completed.' }
        puts ''
        puts 'Deployment User'
        puts ('-' * 70)
        puts "User:     " + ANSI.ansi(:bold) { @options[:deploy_user] }
        puts "Password: " + ANSI.ansi(:bold) { @options[:deploy_password] }
        puts "Home:     " + ANSI.ansi(:bold) { @options[:deploy_home] }
        puts ''
        puts 'Server Test Path'
        puts ('-' * 70)
        puts ANSI.ansi(:bold) { flytrap_path }

        logfile.flush
        logfile.close
        @logfile = nil

      end


      private

      def host_info
        @host_info ||= {}
      end

      def host_id
        host_info['ID'] ||= :unknown
      end


      def logfile
        @logfile ||=
            begin
              dir = File.expand_path('~/incline-logs')
              Dir.mkdir(dir) unless Dir.exist?(dir)
              File.open(File.expand_path("#{dir}/prepare-#{@options[:host]}.log"), 'wt')
            end

      end

      def admin_shell
        Shells::SshBashShell.new(
            host: @options[:host],
            port: @options[:port],
            user: @options[:admin_user],
            password: @options[:admin_password],
            retrieve_exit_code: true,
            on_non_zero_exit_code: :raise,
            silence_timeout: 5
        ) do |sh|
          extend_shell sh, '# '
          yield sh
        end
      end

      def deploy_shell
        Shells::SshBashShell.new(
            host: @options[:host],
            port: @options[:port],
            user: @options[:deploy_user],
            password: @options[:deploy_password],
            retrieve_exit_code: true,
            on_non_zero_exit_code: :raise,
            silence_timeout: 5
        ) do |sh|
          extend_shell sh, '$ '
          yield sh
        end
      end

    end
  end
end