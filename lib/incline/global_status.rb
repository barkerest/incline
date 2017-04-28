module Incline
  ##
  # An interface to a global status/lock file.
  #
  # The global status/lock file is a simple two line file.
  # The first line is the global status message.
  # The second line is the global status progress.
  #
  # The real magic comes when we take advantage of exclusive locks.
  # The process that will be managing the status takes an exclusive lock on the status/lock file.
  # This prevents any other process from taking an exclusive lock.
  # It does not prevent other processes from reading from the file.
  #
  # So the main process can update the file at any time, until it releases the lock.
  # The other processes can read the file at any time, and test for the lock state to determine if the main
  # process is still busy.
  #
  #
  class GlobalStatus

    ##
    # Creates a new GlobalStatus object.
    def initialize
      @handle = nil
    end

    ##
    # Gets the path to the global status/lock file.
    def status_file_path
      @status_file_path ||= WorkPath.path_for('global_lock')
    end

    ##
    # Determines if this instance has a lock on the status/lock file.
    def have_lock?
      !!@handle
    end

    ##
    # Determines if any process has a lock on the status/lock file.
    def is_locked?
      begin
        return true if have_lock?
        return true unless acquire_lock
      ensure
        release_lock
      end
      false
    end

    ##
    # Gets the current status message from the status/lock file.
    def get_message
      get_status[:message]
    end

    ##
    # Gets the current progress from the status/lock file.
    def get_percentage
      r = get_status[:percent]
      r.blank? ? nil : r.to_i
    end

    ##
    # Gets the current status from the status/lock file.
    #
    # Returns a hash with three elements:
    #
    # message::
    #   The current status message.
    #
    # percent::
    #   The current status progress.
    #
    # locked::
    #   The current lock state of the status/lock file. (true for locked, false for unlocked)
    #
    def get_status
      r = {}
      if have_lock?
        @handle.rewind
        r[:message] = (@handle.eof? ? 'The current process is busy.' : @handle.readline.strip)
        r[:percent] = (@handle.eof? ? '' : @handle.readline.strip)
        r[:locked] = true
      elsif is_locked?
        if File.exist?(status_file_path)
          begin
            File.open(status_file_path, 'r') do |f|
              r[:message] = (f.eof? ? 'The system is busy.' : f.readline.strip)
              r[:percent] = (f.eof? ? '' : f.readline.strip)
            end
          rescue
            r[:message] = 'The system appears busy.'
            r[:percent] = ''
          end
        else
          r[:message] = 'No status file.'
          r[:percent] = ''
        end
        r[:locked] = true
      else
        r[:message] = 'The system is no longer busy.'
        r[:percent] = '-'
        r[:locked] = false
      end
      r
    end

    ##
    # Sets the status message if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the message.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_message(value)
      return false unless have_lock?
      cur = get_status
      set_status(value, cur[:percent])
    end

    ##
    # Sets the status progress if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the progress.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_percentage(value)
      return false unless have_lock?
      cur = get_status
      set_status(cur[:message], value)
    end

    ##
    # Sets the status message and progress if this instance has a lock on the status/lock file.
    #
    # Returns true after successfully setting the status.
    # Returns false if this instance does not currently hold the lock.
    #
    def set_status(message, percentage)
      return false unless have_lock?
      @handle.rewind
      @handle.truncate 0
      @handle.write(message.to_s.strip + "\n")
      @handle.write(percentage.to_s.strip + "\n")
      @handle.flush
      true
    end

    ##
    # Releases the lock on the status/lock file if this instance holds the lock.
    #
    # Returns true.
    #
    def release_lock
      return true unless @handle
      set_message ''
      @handle.flock(File::LOCK_UN)
      @handle.close
      @handle = nil
      true
    end

    ##
    # Acquires the lock on the status/lock file.
    #
    # Returns true on success or if this instance already holds the lock.
    # Returns false if another process holds the lock.
    #
    def acquire_lock
      return true if @handle
      begin
        @handle = File.open(status_file_path, File::RDWR | File::CREAT)
        raise StandardError.new('Already locked') unless @handle.flock(File::LOCK_EX | File::LOCK_NB)
        @handle.rewind
        @handle.truncate 0
      rescue
        if @handle
          @handle.flock(File::LOCK_UN)
          @handle.close
        end
        @handle = nil
      end
      !!@handle
    end

    ##
    # Determines if any process currently holds the lock on the status/lock file.
    #
    # Returns true if the file is locked, otherwise returns false.
    #
    def self.locked?
      global_instance.is_locked?
    end

    ##
    # Gets the current status from the status/lock file.
    #
    # See #get_status for a description of the returned hash.
    #
    def self.current
      global_instance.get_status
    end

    ##
    # Runs the provided block with a lock on the status/lock file.
    #
    # If a lock can be acquired, a GlobalStatus object is yielded to the block.
    # The lock will automatically be released when the block exits.
    #
    # If a lock cannot be acquire, then false is yielded to the block.
    # The block needs to test for this case to ensure that the appropriate
    # error handling is performed.
    #
    def self.lock_for(&block)
      return unless block_given?
      status = GlobalStatus.new
      if status.acquire_lock
        begin
          yield status
        ensure
          status.release_lock
        end
      else
        yield false
      end
    end

    private

    def self.global_instance
      @global_instance ||= GlobalStatus.new
    end

  end
end

