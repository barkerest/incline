module Incline
  ##
  # This class simply locates a temporary working directory for the application.
  #
  # By default we shoot for shared memory such as /run/shm or /dev/shm.  If those
  # fail, we look to /tmp.
  #
  class WorkPath

    ##
    # Gets the temporary working directory location for the application.
    #
    def self.location
      @location ||= get_location
    end

    ##
    # Gets a path for a specific temporary file.
    #
    def self.path_for(filename)
      location + '/' + filename
    end

    ##
    # Gets the path to the system status file.
    #
    # This file is used by long running processes to log their progress.
    #
    def self.system_status_file
      @system_status_file ||= path_for('system_status')
    end

    private

    def self.app_name
      @app_name ||= Rails.application.class.name.underscore.gsub('/','_')
    end

    def self.try_path(path)
      path += '/incline_' + app_name

      Incline::Log::debug "Trying path '#{path}'..."

      # must exist or be able to be created.
      unless Dir.exist?(path) || Dir.mkdir(path)
        Incline::Log::debug 'Could not create path.'
        return nil
      end

      # must be able to write and delete a test file.
      test_file = path + '/test.file'
      begin
        File.delete(test_file) if File.exist?(test_file)
        File.write(test_file, 'This is only a test file and can safely be deleted.')
        File.delete(test_file)
      rescue
        Incline::Log::debug 'Could not create test file.'
        path = nil
      end

      path
    end

    def self.get_location
      (%w(/run/shm /var/run/shm /dev/shm /tmp) + []).each do |root|
        if Dir.exist?(root)
          loc = try_path(root)
          return loc unless loc.blank?
        end
      end

      nil
    end

  end
end