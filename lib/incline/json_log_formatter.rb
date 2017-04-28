module Incline
  ##
  # A log formatter that writes entries in JSON format (each line is a valid JSON object).
  class JsonLogFormatter < Logger::Formatter

    ##
    # Regular expressions used to auto-classify any matching message as a debug message.
    AUTO_DEBUG_PATTERNS = [
        /^rendered\s/i,
        /started\sget\s"\/assets/i
    ]

    ##
    # Overrides the default formatter behavior to log a JSON line.
    def call(sev, time, _, msg) #:nodoc:
      level = ({
          Logger::DEBUG   => 'DEBUG',
          Logger::INFO    => 'INFO',
          Logger::WARN    => 'WARN',
          Logger::ERROR   => 'ERROR',
          Logger::FATAL   => 'FATAL',
      }[sev] || sev.to_s).upcase

      if msg.present? && AUTO_DEBUG_PATTERNS.find{|pattern| msg =~ pattern}
        return '' if Rails.logger && Rails.logger.level > 0
        level = 'DEBUG'
      end

      if msg.present?
        # And we'll expand exceptions so we get as much info as possible.
        # If you just want the message, make sure you just pass the message.
        if msg.is_a?(Exception)
          msg = "#{msg.message} (#{msg.class})\n#{(msg.backtrace || []).join("\n")}"
        elsif !msg.is_a?(String)
          msg = msg.inspect
        end

        msg = rm_fmt msg

        {
            level: level,
            time: time.strftime('%Y-%m-%d %H:%M:%S'),
            message: msg,
            app_name: Rails.application.app_name,
            app_version: Rails.application.app_version,
            process_id: Process.pid,
        }.to_json + "\r\n"
      else
        ''
      end
    end

    private

    def rm_fmt(msg)
      msg
          .gsub(/\e\[(\d+;?)*[ABCDEFGHfu]/, "\n")   #   any of the "set cursor position" CSI commands.
          .gsub(/\e\[=?(\d+;?)*[A-Za-z]/,'')        #   \e[#;#;#A or \e[=#;#;#A  basically all the CSI commands except ...
          .gsub(/\e\[(\d+;"[^"]+";?)+p/, '')        #   \e[#;"A"p
          .gsub(/\e[NOc]./,'?')                     #   any of the alternate character set commands.
          .gsub(/\e[P_\]^X][^\e\a]*(\a|(\e\\))/,'') #   any string command
          .gsub(/[\x00\x08\x0B\x0C\x0E-\x1F]/, '')  #   any non-printable characters (notice \x0A (LF) and \x0D (CR) are left as is).
          .gsub("\t", ' ')                          #   turn tabs into spaces.
          .gsub("\r\n", "\n")                       #   all CRLF to LF
          .gsub("\r", "\n")                         #   all CR to LF
          .strip                                    #   remove trailing and leading whitespace
    end

  end
end
