require 'incline/version'
require 'incline/log'
require 'erb'

##
# A Rails quick start library.
module Incline

  ##
  # Gets the automatic email configuration for the Incline application.
  #
  # The primary configuration should be stored in +config/email.yml+.
  # If this file is missing, automatic email configuration is skipped and must be manually specified in your
  # application's environment initializer (eg - config/environment/production.rb).
  #
  #   test:
  #     ...
  #   development:
  #     ...
  #   production:
  #     default_url: www.example.com
  #     default_recipient: contact@example.com
  #     sender: noreply@example.com
  #     auth: :plain
  #     start_tls: true
  #     ssl: false
  #     server: smtp.example.com
  #     port: 587
  #
  # You shouldn't use an open relay, a warning will be thrown if you do.
  # But you don't want your login credentials stored in +config/email.yml+ either.
  # Instead, credentials (if any) should be stored in +config/secrets.yml+.
  #
  #   test:
  #     ...
  #   development:
  #     ...
  #   production:
  #     email:
  #       user: noreply@example.com
  #       password: super-secret-password
  #     secret_key_base: ...
  #
  def self.email_config
    @email_config ||=
        begin
          yaml = Rails.root.join('config', 'email.yml')
          if File.exist?(yaml)
            cfg = File.exist?(yaml) ? YAML.load(ERB.new(File.read(yaml)).result) : { }
            cfg = (cfg[Rails.env] || {}).symbolize_keys

            cfg = {
                port: 25,
                auth: :plain,
                start_tls: true,
                ssl: false
            }.merge(cfg)
            
            Incline::Log::warn 'The email configuration is missing the "user" key.' if cfg[:user].blank?
            Incline::Log::warn 'The email configuration is missing the "password" key.' if cfg[:password].blank?
            Incline::Log::error 'The email configuration is missing the "server" key.' if cfg[:server].blank?
            Incline::Log::error 'The email configuration is missing the "sender" key.' if cfg[:sender].blank?
            Incline::Log::error 'The email configuration is missing the "default_url" key.' if cfg[:default_url].blank?
            Incline::Log::error 'The email configuration is missing the "default_recipient" key.' if cfg[:default_recipient].blank?

            def cfg.valid?
              return false if self[:sender].blank? || self[:server].blank? || self[:default_url].blank? || self[:default_recipient].blank?
              true
            end

            cfg.freeze
          else
            Incline::Log::info 'The configuration file "email.yml" does not exist, automatic email configuration disabled.'
            cfg = {}

            def cfg.valid?
              false
            end

            cfg.freeze
          end
        end

  end

  ##
  # Gets a list of key gems with their versions.
  #
  # This is useful for informational displays.
  #
  # Supply one or more patterns for gem names.
  # If you supply none, then the default pattern list is used.
  def self.gem_list(*patterns)
    patterns =
        if patterns.blank?
          default_gem_patterns
        elsif patterns.first.is_a?(::TrueClass)
          default_gem_patterns + patterns[1..-1]
        else
          patterns
        end

    patterns = patterns.flatten.inject([]) { |m,v| m << v unless m.include?(v); m }

    gems = Gem::Specification.to_a.sort{ |a,b| a.name <=> b.name }

    patterns.inject([]) do |ret,pat|
      gems
          .select { |g| (pat.is_a?(::String) && g.name == pat) || (pat.is_a?(::Regexp) && g.name =~ pat) }
          .each do |g|
        ret << [ g.name, g.version.to_s ] unless ret.find { |(name,_)| name == g.name }
      end
      ret
    end

  end

  ##
  # Gets a list of routes for the current application.
  #
  # The returned list contains hashes with :engine, :controller, :action, :name, :verb, and :path keys.
  def self.route_list
    @route_list ||=
        begin
          require 'action_dispatch/routing/inspector'
          get_routes(Rails.application.routes.routes).sort do |a,b|
            if a[:engine] == b[:engine]
              if a[:controller] == b[:controller]
                if a[:action] == b[:action]
                  a[:path] <=> b[:path]
                else
                  a[:action] <=> b[:action]
                end
              else
                a[:controller] <=> b[:controller]
              end
            else
              a[:engine] <=> b[:engine]
            end
          end
        end
  end

  ##
  # Performs a database migration against the configured database.
  def self.migrate!
    ActiveRecord::Migrator.migrate File.expand_path('../../db/migrate', __FILE__), nil
  end
  
  ##
  # Locates and loads a controller's class definition.
  #
  # If found, returns the controller class, otherwise nil.
  def self.get_controller_class(controller_name)
    controller_name += '_controller' unless controller_name =~ /_controller$/
    class_name = controller_name.classify
    
    klass =
        begin
          class_name.constantize
        rescue NameError
          nil
        end
    
    if klass
      unless klass <= ::ActionController::Base
        ::Incline::Log::warn "The '#{class_name}' class does not inherit from 'ActionController::Base'."
        return nil
      end
    end
    
    unless klass
      file_options =
          if controller_name.include?('/')
            ns,_,ctrl = controller_name.rpartition('/')
            [
                "#{ns}/app/controllers/#{ns}/#{ctrl}_controller",
                "app/controllers/#{ns}/#{ctrl}_controller",
                "#{ns}/app/controllers/#{ctrl}_controller",
                "#{ns}/#{ctrl}_controller"
            ]
          else
            [
                "app/controllers/#{controller_name}_controller",
                "#{controller_name}_controller"
            ]
          end
      
      while (file = file_options.shift)
        begin
          require file
          klass = class_name.constantize
          if klass <= ::ActionController::Base
            ::Incline::Log::debug "Found '#{class_name}' in '#{file}'."
          else
            ::Incline::Log::warn "Found '#{class_name}' in '#{file}', but it does not inherit from 'ActionController::Base'."
            klass = nil
          end
          break
        rescue LoadError, NameError
          # don't bubble up these errors.
          klass = nil
        end
      end
    end
    
    klass
  end

  private

  def self.default_gem_patterns
    @default_gem_patterns ||= [ Rails.application.class.parent_name.underscore, 'rails', /\Aincline(?:-.*)\z/ ]
  end

  def self.get_routes(routes, engine_path = '', engines = [])
    result = []

    routes = routes
                 .collect{|r| ActionDispatch::Routing::RouteWrapper.new(r)}
                 .reject{|r| r.internal?}

    routes.each do |r|
      if r.engine?
        eng_path = r.path
        unless engines.include?(eng_path)
          eng_routes = r.rack_app.routes
          if eng_routes.is_a?(ActionDispatch::Routing::RouteSet)
            engines << eng_path
            result += get_routes(eng_routes.routes, eng_path, engines)
          end
        end
      else
        result << {
            engine:     engine_path,
            controller: r.controller,
            action:     r.action,
            verb:       r.verb,
            path:       engine_path + r.path
        }
      end
    end

    result.inject([]) do |ret,item|
      existing = ret.find{|r| r[:engine] == item[:engine] && r[:controller] == item[:controller] && r[:action] == item[:action]}
      if existing
        existing[:verb] += '|' + item[:verb]
      else
        ret << item
      end
      ret
    end
  end

end

# Include engine after defining base module.
require 'incline/engine'
