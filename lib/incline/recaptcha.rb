require 'cgi/util'

module Incline
  ##
  # A helper class for reCAPTCHA.
  #
  # To use reCAPTCHA, you will need to define +recaptcha_public+ and +recaptcha_private+ in your 'config/secrets.yml'.
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
  class Recaptcha
    ##
    # Determines if recaptcha is disabled either due to a test environment or because :recaptcha_public or :recaptcha_private is not defined in +secrets.yml+.
    def self.disabled?
      Rails.env.test? || public_key.blank? || private_key.blank?
    end

    ##
    # Gets the public key.
    def self.public_key
      @public_key ||= Rails.application.secrets[:recaptca_public].to_s.strip
    end

    ##
    # Gets the private key.
    def self.private_key
      @private_key ||= Rails.application.secrets[:recaptca_private].to_s.strip
    end

    ##
    # Gets the proxy configuration (if any).
    def self.proxy
      @proxy ||= (Rails.application.secrets[:recaptcha_proxy] || {}).symbolize_keys
    end

    ##
    # Generates the bare minimum code needed to include a reCAPTCHA challenge in a form.
    def self.add_recaptcha_challenge
      unless recaptcha_disabled?
        "<div class=\"g-recaptcha\" data-sitekey=\"#{CGI::escape_html(public_key)}\"></div>\n<script src=\"https://www.google.com/recaptcha/api.js\"></script><br>".html_safe
      end
    end

    ##
    # Verifies the response from a reCAPTCHA challenge.
    #
    # Valid options:
    # model::
    #     Sets the model that this challenge is verifying.
    # attribute::
    #     If a model is provided, you can supply an attribute name to assign any error to.
    # response::
    #     If specified, defines the response from the reCAPTCHA challenge that we want to verify.
    #     If not specified, then the request parameters (if any) are searched for the "g-recaptcha-response" value.
    # remote_ip::
    #     If specified, defines the remote IP of the user that was challenged.
    #     If not specified, then the remote IP from the request (if any) is used.
    # request::
    #     Specifies the request to use for information.
    #     This must be provided unless :response and :remote_ip are both specified.
    #
    # Returns true on success, or false on failure.
    #
    def self.verify_recaptcha_challenge(options = {})
      # always true in tests.
      return true if recaptcha_disabled?

      model = options[:model]

      response =
          if model && options[:attribute] && model.respond_to?(options[:attribute])
            model.send(options[:attribute])
          else
            nil
          end

      # model must respond to the 'errors' message and the result of that must respond to 'add'
      if !model || !model.respond_to?('errors') || !model.send('errors').respond_to?('add')
        model = nil
      end

      response ||= options[:response]
      remote_ip = options[:remote_ip]

      if response.blank? || remote_ip.blank?
        request = options[:request]
        raise ArgumentError, 'Either :request must be specified or both :response and :remote_ip must be specified.' unless request
        response = request.params['g-recaptcha-response']
        remote_ip = request.respond_to?(:remote_ip) ? request.send(:remote_ip) : ENV['REMOTE_ADDR']
      end

      begin
        if proxy.blank?
          http = Net::HTTP
        else
          http = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password)
        end

        verify_hash = {
            secret: private_key,
            remoteip: remote_ip,
            response: response
        }

        recaptcha = nil
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
            model.errors.add(options[:attribute] || :base, 'Recaptcha verification failed.')
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