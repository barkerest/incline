
module Incline
  class CLI
    class Prepare
      
      # create setuid utilities to test the config and reload the config.
      
      UTIL_NGINX_RELOAD = <<-EOU
#include <unistd.h>

int main(int argc, char **argv)
{
  const char *args[] = { "??NG", "-s", "reload", NULL };
  setuid(0);
  execv(args[0], (char **)args);
  return 0;
}
      EOU

      UTIL_NGINX_TEST = <<-EOU
#include <unistd.h>

int main(int argc, char **argv)
{
  const char *args[] = { "??NG", "-t", "-q", NULL };
  setuid(0);
  execv(args[0], (char **)args);
  return 0;
}
      EOU


      private_constant :UTIL_NGINX_RELOAD, :UTIL_NGINX_TEST
      
      private
      
      def create_nginx_utils(shell)
        shell.with_status('Creating utilities') do
          nginx_path = shell.exec("which nginx").split("\n").first.to_s.strip
  
          { 'nginx-reload' => UTIL_NGINX_RELOAD, 'nginx-test' => UTIL_NGINX_TEST }.each do |util,src|
            shell.write_file "#{shell.home_path}/temp-util.c", src.gsub("??NG", nginx_path)
            shell.exec "gcc -o #{shell.home_path}/#{util} #{shell.home_path}/temp-util.c"
            shell.sudo_exec "chown root:root #{shell.home_path}/#{util} && chmod 4755 #{shell.home_path}/#{util}"
            shell.sudo_exec "mv -f #{shell.home_path}/#{util} /usr/local/bin/#{util}"
            shell.exec "rm #{shell.home_path}/temp-util.c"
          end
        end
      end
    end
  end
end