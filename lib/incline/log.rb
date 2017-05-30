require 'ansi/code'

module Incline
  ##
  # A logging wrapper to tag log messages with location information.
  class Log

    ##
    # Logs a debug message.
    def self.debug(msg = nil, &block)
      safe_log :debug, msg, &block
    end

    ##
    # Logs an info message.
    def self.info(msg = nil, &block)
      safe_log :info, msg, &block
    end

    ##
    # Logs a warning message.
    def self.warn(msg = nil, &block)
      safe_log :warn, msg, &block
    end

    ##
    # Logs an error message.
    def self.error(msg = nil, &block)
      safe_log :error, msg, &block
    end

    ##
    # Gets a list of paths that are considered root paths for logging purposes.
    def self.root_paths
      @root_paths ||=
          begin
            [
                Rails.root.to_s,
                File.expand_path('../../../', __FILE__)
            ]
                .map{|v| v[-1] == '/' ? v : "#{v}/"}
          end
    end

    ##
    # Set output to go to a file.
    #
    # If a +file+ is specified, it will be used for output.  This will bypass Rails logging.
    # If +file+ is set to false or nil then the default logging behavior will be used.
    def self.set_output(file)
      if file
        if file.respond_to?(:puts)
          @output = file
          @rails = nil
        elsif file.is_a?(::String)
          @output = File.open(file, 'wt')
          @rails = nil
        else
          raise ArgumentError, 'The file parameter must be an IO-like object, a string path, or a false value.'
        end
      else
        # reset behavior
        remove_instance_variable(:@output) if instance_variable_defined?(:@output)
        remove_instance_variable(:@rails) if instance_variable_defined?(:@rails)
      end
    end

    ##
    # Gets the current logging output.
    def self.get_output
      rails&.logger || output
    end

    private

    def self.output
      # always returns something.
      (instance_variable_defined?(:@output) ? instance_variable_get(:@output) : $stderr) || $stderr
    end

    def self.skip?(level)
      filt_level = (log_level || 0)
      if filt_level > 0
        return true if level == :debug
        return true if level == :info && filt_level > 1
        return true if level == :warn && filt_level > 2
      end
      false
    end

    def self.rails
      unless instance_variable_defined?(:@rails)
        @rails = Object.const_defined?(:Rails) ? Object.const_get(:Rails) : nil
      end
      @rails
    end

    def self.log_level
      rails&.logger&.level
    end

    def self.safe_log(level, msg)
      return '' if skip?(level)

      # by allowing a block, we can defer message processing and skip it altogether when the level is being silenced.
      msg = yield if block_given?

      c = caller_locations(2,1)[0]
      c = "#{relative_path(c.path)}:#{c.lineno}:in `#{c.base_label}`"
      msg = "[#{c}] #{msg_to_str(msg)}"

      if rails&.logger
        rails.logger.send level, msg
      else
        level = case level
                  when :error
                    ANSI.ansi level.to_s.upcase, :bright, :red
                  when :warn
                    ANSI.ansi level.to_s.upcase, :yellow
                  when :info
                    ANSI.ansi level.to_s.upcase, :bright, :white
                  else
                    level.to_s.upcase
                end

        output.puts "#{level}: #{msg}"
      end

      msg
    end

    def self.relative_path(path)
      path = path.to_s
      root_paths.each do |rp|
        if path[rp]
          return path[rp.length..-1]
        end
      end
      path
    end

    def self.msg_to_str(msg)
      if msg.is_a?(::Exception)
        "#{msg.message} (#{msg.class})\n#{(msg.backtrace || []).join("\n")}"
      elsif msg.is_a?(::String)
        msg
      else
        msg.inspect
      end
    end

  end
end