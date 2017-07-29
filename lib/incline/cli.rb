require 'ansi/code'
require 'incline/version'
require 'incline/cli/errors'

require 'incline/cli/helpers/yaml'

require 'incline/cli/version'
require 'incline/cli/usage'


module Incline
  class CLI


    def initialize

    end

    def execute(*args)
      begin
        if args.empty? || %w(usage help /? -? -help --help).include?(args.first)
          process_command(:usage)
        else
          process_command(*args)
        end
      rescue UsageError => err
        STDERR.puts err.message
        process_command(:usage)
      rescue CliError => err
        STDERR.puts ANSI.code(:red) { 'ERROR:' }
        STDERR.puts err.message
      rescue RuntimeError => err
        STDERR.puts ANSI.code(:red) { 'FATAL ERROR:' }
        STDERR.puts err.inspect
      end
    end

    def process_command(command, *args)
      command = command.to_sym
      cmd_info = self.class.command_list.find{|c| c[:method] == command}
      if cmd_info
        args = args.dup
        args = []
        cmd_info[:new_params].each do |(type,name)|
          if type == :rest
            args += args
            break
          elsif type == :req
            if args.empty?
              raise UsageError, "Missing required parameter '#{name}' for command '#{command}'."
            end
            args << args.delete_at(0)
          elsif type == :opt
            if args.empty?
              break
            else
              args << args.delete_at(0)
            end
          else
            raise UsageError, "Unknown parameter type '#{type}' for command '#{command}'."
          end
        end
        cmd_object = cmd_info[:klass].new(*args)
        cmd_object.send(:run)
      else
        raise UsageError, "Unknown command '#{command}'."
      end
    end

    def self.valid_commands
      command_list.map do |cmd_info|
        [ cmd_info[:method], cmd_info[:klass], cmd_info[:new_params] ]
      end
    end

    private

    def self.command_list
      @command_list ||=
          begin
            constants.map do |c|
              klass = const_get c
              # class must have a :new class method and a :run instance method.
              if klass.instance_methods.include?(:run) && klass.methods.include?(:new)
                m = klass.method(:new)
                new_params = m.parameters.select{ |p| p[1] && (p[0] == :req || p[0] == :opt || p[0] == :rest) }.freeze
                m = klass.instance_method(:run)
                run_params = m.parameters.select{ |p| p[1] && (p[0] == :req || p[0] == :opt || p[0] == :rest) }.freeze
                if run_params.count == 0
                  {
                      name: c.to_s,
                      method: c.to_s.gsub(/(.)([A-Z])/,"\\1_\\2").downcase.to_sym,
                      new_params: new_params,
                      klass: klass,
                      valid: true
                  }
                else
                  {
                      name: c.to_s,
                      valid: false,
                      failure_reason: 'Method :run expects parameters.'
                  }
                end
              else
                {
                    name: c,
                    valid: false,
                    failure_reason: 'Missing :new or :run.'
                }
              end
            end.select do |c|
              c[:valid]
            end
          end
    end



  end
end