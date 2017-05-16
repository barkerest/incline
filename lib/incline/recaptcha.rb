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
    # Gets the valid themes for the reCAPTCHA field.
    VALID_THEMES = [ :dark, :light ]

    ##
    # Gets the valid types for the reCAPTCHA field.
    VALID_TYPES = [ :audio, :image ]

    ##
    # Gets the valid sizes for the reCAPTCHA field.
    VALID_SIZES = [ :compact, :normal ]

    ##
    # Determines if recaptcha is disabled either due to a test environment or because :recaptcha_public or :recaptcha_private is not defined in +secrets.yml+.
    def self.disabled?
      Rails.env.test? || public_key.blank? || private_key.blank?
    end

    ##
    # Gets the public key.
    def self.public_key
      @public_key ||= Rails.application.secrets[:recaptcha_public].to_s.strip
    end

    ##
    # Gets the private key.
    def self.private_key
      @private_key ||= Rails.application.secrets[:recaptcha_private].to_s.strip
    end

    ##
    # Gets the proxy configuration (if any).
    def self.proxy
      @proxy ||= (Rails.application.secrets[:recaptcha_proxy] || {}).symbolize_keys
    end


    ##
    # Generates the bare minimum code needed to include a reCAPTCHA challenge in a form.
    def self.add
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
    #     If a model is provided, you can supply an attribute to retrieve the response data from.
    #     This attribute should return a hash with :response and :remote_ip keys.
    #     If this is provided, then the remaining options are ignored.
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
    def self.verify(options = {})
      # always true in tests.
      return true if recaptcha_disabled?

      model = options[:model]

      response =
          if model && options[:attribute] && model.respond_to?(options[:attribute])
            model.send(options[:attribute])
          else
            nil
          end

      remote_ip = nil

      if response.is_a?(::Hash)
        remote_ip = response[:remote_ip]
        response = response[:response]
      end

      # model must respond to the 'errors' message and the result of that must respond to 'add'
      if !model || !model.respond_to?('errors') || !model.send('errors').respond_to?('add')
        model = nil
      end

      response ||= options[:response]
      remote_ip ||= options[:remote_ip]

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


    ##
    # Defines a reCAPTCHA tag that can be used to supply a field in a model with a hash of values.
    #
    # Basically we define two fields for the model attribute, one for :remote_ip and one for :response.
    # The :remote_ip field is set automatically and shouldn't be changed.
    # The :response field is set when the user completes the challenge.
    #
    #   Incline::Recaptcha::Tag.new(my_model, :is_robot).render
    #
    #   <input type="hidden" name="my_model[is_robot][remote_ip]" id="my_model_is_robot_remote_ip" value="10.11.12.13">
    #   <input type="hidden" name="my_model[is_robot][response]" id="my_model_is_robot_response" value="">
    #
    #   Incline::Recaptcha::verify model: my_model, attribute: :is_robot
    class Tag < ActionView::Helpers::Tags::Base

      ##
      # Generates the reCAPTCHA data.
      def render
        response_id = tag_id + '_response'
        remote_ip_id = tag_id + '_remote_ip'

        remote_ip =
            if @template_object&.respond_to?(:request) && @template_object.send(:request)&.respond_to?(:remote_ip)
              @template_object.request.remote_ip
            else
              ENV['REMOTE_ADDR']
            end

        ret =   tag('input', type: 'hidden', id: remote_ip_id, name: tag_name + '[][remote_ip]', value: remote_ip)
        ret +=  "\n"
        ret +=  tag('input', type: 'hidden', id: response_id, name: tag_name + '[][response]', value: '')
        ret +=  "\n"

        opts = {
            :class           => 'g-recaptcha',
            :data => {
                :sitekey     => CGI::escape_html(Incline::Recaptcha::public_key),
                :callback    => 'update_' + response_id,
                :tabindex    => @options[:tab_index].to_s.to_i,
                :theme       => make_valid(@options[:theme], VALID_THEMES, :light),
                :type        => make_valid(@options[:type], VALID_TYPES, :image),
                :size        => make_valid(@options[:size], VALID_SIZES, :normal)
            }
        }

        ret +=  tag('div', class: 'form-group')
        ret +=  tag('div', opts, true)
        ret +=  "</div></div>\n".html_safe

        ret += <<-EOS.html_safe
<script type="text/javascript">
// <![CDATA[
function update_#{response_id}(response) { $('##{response_id}').val(response); }
// ]]>
</script>
<script type="text/javascript" src="https://www.google.com/recaptcha/api.js"></script>
        EOS

        ret.html_safe
      end

      private

      def make_valid(value, valid, default)
        return default if value.blank?
        value = value.to_sym
        return default unless valid.include?(value)
        value
      end

    end

  end
end