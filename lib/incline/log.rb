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


    private

    def self.skip?(level)
      max_level = (Rails.logger&.level || 0)
      if max_level > 0
        return true if level == :debug
        return true if level == :info && max_level > 1
        return true if level == :warn && max_level > 2
      end
      false
    end

    def self.safe_log(level, msg)
      return '' if skip?(level)

      # by allowing a block, we can defer message processing and skip it altogether when the level is being silenced.
      msg = yield if block_given?

      c = caller_locations(2,1)[0]
      c = "#{relative_path(c.path)}:#{c.lineno}:in `#{c.base_label}`"
      msg = "[#{c}] #{msg_to_str(msg)}"

      if Rails.logger
        Rails.logger.send level, msg
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

        puts "#{level}: #{msg}"
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
      if msg.is_a?(Exception)
        "#{msg.message} (#{msg.class})\n#{(msg.backtrace || []).join("\n")}"
      elsif msg.is_a?(String)
        msg
      else
        msg.inspect
      end
    end

  end
end