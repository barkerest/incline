module Incline

  ##
  # Makes 'main_app' automatically get searched for methods.
  module MainAppExtension

    def self.included(base) # :nodoc:
      base.class_eval do

        # :nodoc:
        alias :incline_original_method_missing :method_missing

        def method_missing(method, *args, &block) # :nodoc:
          if respond_to?(:main_app)
            main_app = send(:main_app)
            if main_app && main_app.respond_to?(method)
              return main_app.send(method, *args, &block)
            end
          end

          incline_original_method_missing(method, *args, &block)
        end

      end
    end

  end

end

ActionController::Base.include Incline::MainAppExtension
ActionMailer::Base.include Incline::MainAppExtension
ActionView::Base.include Incline::MainAppExtension