require 'action_mailer'

module Incline::Extensions

  ##
  # Adds the default_hostname, default_sender, and default_recipient methods to the ApplicationMailer::Base class.
  module ActionMailerBase

    ##
    # Adds the extra class methods to the ApplicationMailer::Base class.
    module ClassMethods
      ##
      # Gets the default hostname for messages.
      def default_hostname
        @default_hostname ||= Incline::email_config[:default_hostname]
      end

      ##
      # Gets the default sender for messages.
      def default_sender
        @default_sender ||= Incline::email_config[:sender]
      end

      ##
      # Gets the default recipient for messages.
      def default_recipient
        @default_recipient ||= Incline::email_config[:default_recipient]
      end
    end

    ##
    # Sets the default from and to address according to the configuration.
    def self.included(base)
      base.extend ClassMethods

      class << self

        private

        if method_defined?(:inherited)
          alias_method :incline_original_inherited, :inherited
        else
          def incline_original_inherited(subclass)
            # Do nothing.
          end
        end

        def inherited(subclass)
          incline_original_inherited subclass

          default(
              {
                  from: default_sender,
                  to: default_recipient
              }
          )
        end
      end

    end

  end

end

ActionMailer::Base.include Incline::Extensions::ActionMailerBase