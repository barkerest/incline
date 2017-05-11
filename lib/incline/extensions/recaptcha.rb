module Incline::Extensions
  ##
  # Adds methods to views and controllers to work with reCAPTCHA.
  #
  # You will need to define +recaptcha_public+ and +recaptcha_private+ in your 'config/secrets.yml'.
  # If you need to use a proxy server, you will need to configure the proxy settings as well.
  #
  #   # config/secrets.yml
  #   default: &default
  #     recaptcha_public: SomeBase64StringFromGoogle
  #     recaptcha_private: AnotherBase64StringFromGoogle
  #     recaptcha_proxy:
  #       host: 10.10.10.10
  #       port: 1000
  #       user: username
  #       password: top_secret
  #
  module Recaptcha

    ##
    # Contains the view methods and some controller methods.
    module Common
      ##
      # Determines if recaptcha is disabled either due to a test environment or because :recaptcha_public or :recaptcha_private is not defined in +secrets.yml+.
      def recaptcha_disabled?
        Rails.env.test? || Rails.application.secrets[:recaptcha_public].blank? || Rails.application.secrets[:recaptcha_private].blank?
      end

      ##
      # Adds the recaptcha challenge to a form.
      #
      # This would generally be best placed after form content but before the submit button.
      #
      def add_recaptcha_challenge
        unless recaptcha_disabled?
          "<div class=\"g-recaptcha\" data-sitekey=\"#{h Rails.application.secrets[:recaptcha_public]}\"></div>\n<script src=\"https://www.google.com/recaptcha/api.js\"></script><br>".html_safe
        end
      end

    end

    ##
    # Contains the controller methods.
    module Controller

      ##
      # Verifies the response from a recaptcha challenge.
      #
      # If the model is provided, this will add an error to the model on failure.
      # This makes notifying the user seem more integrated.
      #
      # Returns true on success, or false on failure.
      #
      def verify_recaptcha_challenge(model = nil)

        # always true in tests.
        return true if recaptcha_disabled?

        # model must respond to the 'errors' message and the result of that must respond to 'add'
        if !model || !model.respond_to?('errors') || !model.send('errors').respond_to?('add')
          model = nil
        end

        begin
          recaptcha = nil

          if Rails.application.secrets[:recaptcha_proxy].blank?
            http = Net::HTTP
          else
            proxy_server = Rails.application.secrets[:recaptcha_proxy].symbolize_keys
            http = Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
          end

          # get the remote IP from either request.remote_ip or env['REMOTE_ADDR']
          remote_ip = (respond_to?('request') && request && request.respond_to?('remote_ip') && request.remote_ip) || (respond_to?('env') && env && env['REMOTE_ADDR'])

          verify_hash = {
              secret: Rails.application.secrets[:recaptcha_private],
              remoteip: remote_ip,
              response: params['g-recaptcha-response']
          }

          Timeout::timeout(5) do
            uri = URI.parse('https://www.google.com/recaptcha/api/siteverify')
            http_instance = http.new(uri.host, uri.port)
            if uri.port == 443
              http_instance.use_ssl = true
            end
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(verify_hash)
            recaptcha = http_instance.request(request)
          end
          answer = JSON.parse(recaptcha.body)

          unless answer['success'].to_s.downcase == 'true'
            if model
              model.errors.add(:base, 'Recaptcha verification failed.')
            end
            return false
          end

          return true
        rescue Timeout::Error
          if model
            model.errors.add(:base, 'Recaptcha unreachable.')
          end
        end

        false
      end
    end

  end
end

