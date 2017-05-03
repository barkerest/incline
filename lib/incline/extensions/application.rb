require 'cgi/util'
require 'yaml'
require 'fileutils'

module Incline::Extensions
  ##
  # Adds some informational methods to the Application class.
  module Application

    ##
    # Is the rails server running?
    def running?
      path = File.join(Rails.root, 'tmp/pids/server.pid')
      pid = File.exist?(path) ? File.read(path).to_i : -1
      server_running = true
      begin
        Process.getpgid pid
      rescue Errno::ESRCH
        server_running = false
      end
      server_running
    end

    ##
    # Gets the application name.
    #
    # You should override this method in your +application.rb+ file to return the appropriate value.
    def app_name
      default_notify :app_name
      'Incline'
    end

    ##
    # Gets the application instance name.
    #
    # This can be set by creating a +config/instance.yml+ configuration file and setting the 'name' property.
    # The instance name is used to create unique cookies for each instance of an application.
    # The default instance name is 'default'.
    def app_instance_name
      @app_instance_name ||=
          begin
            yaml = Rails.root.join('config','instance.yml')
            if File.exist?(yaml)
              yaml = (YAML.load_file(yaml) || {}).symbolize_keys
              yaml[:name].blank? ? 'default' : yaml[:name]
            else
              'default'
            end
          end
    end

    ##
    # Gets the application version.
    #
    # You should override this method in your +application.rb+ file to return the appropriate value.
    def app_version
      default_notify :app_version
      '0.0.1'
    end

    ##
    # Gets the company owning the copyright to the application.
    #
    # You should override this method in your +application.rb+ file to return the appropriate value.
    def app_company
      default_notify :app_company
      'BarkerEST'
    end

    ##
    # Gets the year of copyright ownership for the company.
    #
    # Defaults to the current year (at the time of execution).
    def app_copyright_year
      Time.now.year.to_s
    end

    ##
    # Gets the application name and version.
    def app_info
      "#{app_name} v#{app_version}"
    end

    ##
    # Gets the copyright statement for this application.
    def app_copyright(html = true)
      if html
        "Copyright &copy; #{CGI::escapeHTML app_copyright_year} #{CGI::escapeHTML app_company}".html_safe
      else
        "Copyright (C) #{app_copyright_year} #{app_company}"
      end
    end

    ##
    # Is a restart currently pending.
    def restart_pending?
      return false unless File.exist?(restart_file)
      request_time = File.mtime(restart_file)
      request_time > Incline.start_time
    end

    ##
    # Updates the restart file to indicate we want to restart the web app.
    def request_restart!
      Incline::Log::info 'Requesting an application restart.'
      FileUtils.touch restart_file
      File.mtime restart_file
    end

    ##
    # Generates a cookie name using the application name and instance name.
    def cookie_name(cookie)
      "_incline_#{app_name.downcase.scan(/[a-z0-9]+/).join('_')}_#{app_instance_name.downcase.scan(/[a-z0-9]+/).join('_')}_#{cookie}"
    end


    private

    def default_notify(property)
      @default_notify ||= {}
      @default_notify[property] ||= 0
      if @default_notify[property] == 0
        @default_notify[property] = 1
        Incline::Log::warn "Default \"#{property}\" is in use.  Please define \"#{property}\" in your \"application.rb\" file."
      end
    end

    def restart_file
      @restart_file ||= "#{self.config.root}/tmp/restart.txt"
    end

  end

end

Rails::Application.include Incline::Extensions::Application