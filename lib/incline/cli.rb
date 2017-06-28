
require 'incline/version'
require 'incline/log'


module Incline
  ##
  # The command line interface for Incline.
  #
  #     incline help
  class Cli

    class CliError < ::RuntimeError

    end

    ##
    # Initializes an instance of the CLI with the specified parameters.
    def initialize(*params)
      @run_method = nil
      @params = nil
      @help_message = nil

      if params && params.count > 0 && params.last.is_a?(::Hash)
        opts = params.delete(params.last)
        @help_message = opts[:help_message]

      end

      if params && params.count > 0
        begin
          @run_method = params.delete_at(0).to_s.to_sym
          @run_method = :help if [ :'?', :'/?', :'-?', :'/help', :'-help', :'--help' ].include?(@run_method)

          if respond_to?(@run_method)
            @run_method = method(@run_method)
          else
            raise CliError, "ERROR: '#{@run_method}' is not a valid command."
          end
        rescue NameError
          raise CliError, "ERROR: '#{@run_method}' is not a valid command."
        end

        if params.count > @run_method.parameters.count && (@run_method.parameters.count < 1 || @run_method.parameters.last[0] != :rest)
          raise CliError, "ERROR: Too many arguments for '#{@run_method.name}' command."
        elsif @run_method.parameters.count > 0
          @params = []
          @run_method.parameters.each_with_index do |(req,nam),i|
            if i >= params.count && req == :req
              raise CliError, "ERROR: The '#{nam}' parameter is required for the '#{@run_method.name}' command."
            end
            if req == :rest
              @params += params[i..-1].map(&:to_s)
            else
              @params << params[i].to_s
            end
          end
        end
      end

    end

    ##
    # Shows the help text.
    def help
      puts "Incline v#{Incline::VERSION}"
      puts '-' * 79
      if @help_message.to_s.strip != ''
        puts @help_message
        puts '-' * 79
      end
      {
          help: 'Show this help text.',
          new: 'Create a new Rails application using the Incline gem.',
      }.each do |cmd,desc|
        meth = method(cmd)
        puts desc
        cmd = "incline #{cmd}"
        closer = ''
        meth.parameters.each do |(r,p)|
          cmd += ' '
          unless r == :req
            cmd += '['
            closer += ']'
          end
          cmd += '*' if r == :rest
          cmd += p.to_s
        end
        cmd += closer
        puts cmd
        puts ''
      end
    end

    ##
    # Creates a new incline application with the specified name.
    def new(name, *options)
      unless name =~ /\A[a-z][a-z0-9_]*\z/
        raise CliError, "ERROR: The 'name' parameter for the 'new' command must be lowercase, start with\na letter, and only contain letters, numbers and underscores."
      end

      index = options.index('--mount-path')
      mount_path = nil
      if index
        options.delete_at(index)                # remove --mount-path
        mount_path = options.delete_at(index)   # remove argument.
      else
        index = options.index{|arg| arg =~ /^--mount-path=/}
        if index
          mount_path = options
                           .delete_at(index)    # remove --mount-path=...
                           .partition('=')[2]   # take everything after the '='.
        end
      end
      mount_path = 'incline' if mount_path.to_s.strip == ''

      json_logger = true
      options.delete('--json-logger')
      if options.delete('--no-json-logger')
        json_logger = false
      end

      force_copy = true
      options.delete('--force-copy')
      if options.delete('--no-force-copy')
        force_copy = false
      end

      %w(turbolinks spring).each do |opt|
        options.delete '--skip-' + opt
        options.delete '--no-skip-' + opt
      end

      options << '--skip-turbolinks'
      options << '--skip-spring'
      options << '-m'
      options << File.expand_path('../../generators/incline/templates/incline_app.rb',__FILE__)
      options.insert 0, 'rails', 'new', name

      # Generate the application and run the bundle.
      unless system(*options)
        raise CliError, "ERROR: Failed to generate new rails application named '#{name}'."
      end

      orig_dir = Dir.pwd
      begin
        # drop into the newly created application.
        Dir.chdir name

        unless system(
            'bundle',
            'exec',
            'rails',
            'generate',
            'incline:install',
            '--mount-path=' + mount_path,
            json_logger ? '--json-logger' : '--no-json-logger',
            force_copy ? '--force-copy' : '--no-force-copy'
        )
          raise CliError, "ERROR: Failed to install Incline gem into application named '#{name}'."
        end
      ensure
        Dir.chdir orig_dir
      end
    end

    ##
    # Runs this instance of the CLI with the supplied arguments.
    def run
      @run_method ||= method(:help)
      if @params
        @run_method.call(*@params)
      else
        @run_method.call
      end
    end

    private

    def template_path
      @template_path ||= File.expand_path('../../templates/incline', __FILE__)
    end


  end
end

