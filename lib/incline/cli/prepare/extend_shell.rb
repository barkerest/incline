module Incline
  class CLI
    class Prepare
      
      private

      # Add full logging to the shell along with a few helper methods.
      # The prefix is used to identify the shell creating the messages and will be prefixed to each line in the log.
      def extend_shell(sh, prefix)
        logfile.write "\n" + prefix
        sh.instance_variable_set :@prep_log, logfile
        sh.instance_variable_set :@prep_prefix, "\n#{prefix}"
        sh.instance_variable_set :@stat_count, -1
        sh.instance_variable_set :@stat_every, 128
        sh.instance_variable_set :@home_path, nil

        def sh.home_path
          @home_path ||= exec_ignore_code("eval echo \"~#{@options[:user]}\"").to_s.split("\n").first.to_s.strip
        end

        def sh.with_stat(status, stat_every = 128)
          if @stat_count > -1
            yield
          else
            @stat_count = 0
            @stat_every = stat_every < 1 ? 128 : stat_every
            print status
            yield
            print "\n"
            @stat_count = -1
            @stat_every = 128
          end
        end

        def sh.exec(cmd, options = {}, &block)
          super(cmd, options) do |data, type|
            @prep_log.write data.gsub("\n", @prep_prefix)
            @prep_log.flush
            if @stat_count > -1
              @stat_count += data.length
              while @stat_count >= @stat_every
                @stat_count -= @stat_every
                print '.'
              end
            end
            if block
              block.call data, type
            else
              nil
            end
          end
        end

        def sh.stat_exec(status, cmd, options = {}, &block)
          with_stat(status) { exec(cmd, options, &block) }
        end

        def sh.sudo_stat_exec(status, cmd, options = {}, &block)
          with_stat(status) { sudo_exec(cmd, options, &block) }
        end

        def sh.apt_get(command)
          sudo_exec "DEBIAN_FRONTEND=noninteractive apt-get -y -q #{command}"
        end

        def sh.get_user_id(user)
          result = exec_ignore_code("id -u #{user} 2>/dev/null").to_s.split("\n")
          result.any? ? result.first.strip.to_i : 0
        end

        def sh.host_info
          @host_info ||=
              begin
                results = exec('cat /etc/*-release').split("\n").map{|s| s.strip}.reject{|s| s == ''}
                info = {}

                results.each do |line|
                  if line.include?('=')
                    var,_,val = line.partition('=').map{|s| s.strip}
                    val = val[1...-1] if val[0] == '"' && val[-1] == '"'
                    var.upcase!
                    info[var] = val
                  end
                end

                info['ID'] = (info['ID'] || 'unknown').downcase.to_sym
                info['NAME'] ||= info['ID'].to_s
                info['VERSION'] ||= '??'
                info['PRETTY_NAME'] ||= "#{info['NAME']} #{info['VERSION']}"

                puts info['PRETTY_NAME']

                info
              end
        end

        sh
      end
      
    end
  end
end