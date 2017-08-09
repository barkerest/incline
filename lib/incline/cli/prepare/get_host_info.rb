
module Incline
  class CLI
    class Prepare
      
      private
      
      def get_host_info(shell)
        results = shell.exec('cat /etc/*-release').split("\n").map{|s| s.strip}.reject{|s| s == ''}
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
  end
end