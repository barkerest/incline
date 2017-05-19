module Incline::Extensions

  ##
  # Makes 'main_app' automatically get searched for methods.
  module MainApp

    def self.included(base) # :nodoc:
      base.class_eval do

        # :nodoc:
        alias :incline_mainapp_original_method_missing :method_missing

        def method_missing(method, *args, &block) # :nodoc:
          o_main_app = if respond_to?(:main_app)
                         send(:main_app)
                       else
                         Rails.application.class.routes.url_helpers
                       end
          
          if o_main_app && o_main_app.respond_to?(method)
            return o_main_app.send(method, *args, &block)
          end
          
          incline_mainapp_original_method_missing(method, *args, &block)
        end

      end
    end

  end

end

ActionController::Base.include Incline::Extensions::MainApp
ActionMailer::Base.include Incline::Extensions::MainApp
ActionView::Base.include Incline::Extensions::MainApp
