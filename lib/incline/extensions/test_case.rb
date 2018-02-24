require 'active_support'

module Incline::Extensions
  ##
  # Adds some extra assertions and methods for use in tests.
  module TestCase
    ##
    # Adds the #access_tests_for method.
    module ClassMethods
      ##
      # This method will generate multiple generic access tests for your controller.
      #
      # The +action+ argument can be one or more actions to test.  These can be specified as arguments or an array.
      #   access_tests_for :new, :edit, :show
      #   access_tests_for [ :new, :edit, :show ]
      #
      # Options are provided after the last action to test.  All options will be applied to all actions.
      # The {action}_params option being the only one that is explicitly for a specific action.
      #
      # Valid options:
      # controller::
      #     The name of the controller.  If not supplied, the controller is inferred from the class name.
      # url_helper::
      #     The code used to generate the URL.  If not supplied, the helper is inferred from the controller and action name.
      # fixture_helper::
      #     A string defining the fixture helper to use.  If not supplied the pluralized controller name will be used.
      # fixture_key::
      #     The key to use to load a fixture.  The default is :one.
      # allow_anon::
      #     Determines if anonymous users should be able to access the action.  The default is false.
      # allow_any_user::
      #     Determines if any authenticated user should be able to access the action.  The default is false.
      # allow_groups::
      #     Specifies a list of groups that should be able to access the action.  The default is nil.
      # deny_groups::
      #     Specifies a list of groups that should not be able to access the action.  The default is nil.
      # allow_admin::
      #     Specifies if a system admin should be able to access the action.  The default is true.
      # method::
      #     Specifies the method to process the action with.  The default is 'get'.
      # success::
      #     Determines the result on success.  Defauls to :success for 'get' requests, otherwise the pluralized controller helper path.
      # failure::
      #     Determines the result on failure for non-anon tests.  Defaults to 'main_app.root_path'.
      # anon_failure::
      #     Determines the result on failure for anon tests.  Defaults to 'incline.login_path'.
      # {action}_params::
      #     You can pass params to the action by specifying a hash containing them in this fashion.
      #     e.g. - :new_params => { }  # params for :new action
      # return_code::
      #     If this is set to a true value, the test code is generated, but not executed.  The test code will then
      #     be returned as a string.
      #     If this is not to a true value, the test code will be executed as generated and nil will be returned.
      #
      #   access_tests_for :new, controller: 'users', allow_anon: true, allow_any_user: false, allow_admin: false
      #
      def access_tests_for(*actions)

        options = actions.delete(actions.last) if actions.last.is_a?(::Hash)
        options ||= { }

        if actions.count == 1 && actions.first.is_a?(::Array)
          actions = actions.first
        end

        if actions.count > 1
          data = actions.map{|act| access_tests_for(act, options.dup)}
          if options[:return_code]
            return data.join
          else
            return nil
          end
        end

        action = actions.first

        options = {
            allow_anon:         false,
            allow_any_user:     false,
            allow_groups:       nil,
            deny_groups:        nil,
            allow_admin:        true,
            fixture_key:        :one,
            failure:            'main_app.root_path',
            anon_failure:       'incline.login_path'
        }.merge((options || {}).symbolize_keys)

        action = action.to_sym
        params = options[:"#{action}_params"]
        params = params.inspect if params.is_a?(::Hash)
        params = nil unless params.is_a?(::String)

        # guess at the method to use.
        if options[:method].blank?
          options[:method] =
              if action == :destroy
                'delete'
              elsif action == :update
                'patch'
              elsif action == :create
                'post'
              else
                'get'
              end
        end
        options[:method] = options[:method].to_sym

        if options[:controller].blank?
          # only works with controller tests (eg - UsersControllerTest => users_controller_test => users_controller)
          options[:controller] = self.name.underscore.rpartition('_')[0]
        else
          options[:controller] = options[:controller].to_s.underscore
        end

        if options[:controller] =~ /_controller$/
          options[:controller] = options[:controller].rpartition('_')[0]
        end

        if options[:fixture_helper].blank?
          options[:fixture_helper] = options[:controller].pluralize
        end

        if options[:url_helper].blank?
          fix_val = "#{options[:fixture_helper]}(#{options[:fixture_key].inspect})"
          options[:url_helper] =
              case action
                when :show, :update, :destroy   then  "#{options[:controller].singularize}_path(#{fix_val})"
                when :edit                      then  "edit_#{options[:controller].singularize}_path(#{fix_val})"
                when :new                       then  "new_#{options[:controller].singularize}_path"
                else                                  "#{options[:controller].pluralize}_path"
              end
        end

        if options[:success].blank?
          if options[:method] == :get
            options[:success] = :success
          else
            options[:success] = "#{options[:controller].pluralize}_path"
          end
        end


        method = options[:method]
        url_helper = options[:url_helper]

        tests = [
            #   label         result                    user    group   success_override    failure_override
            [ 'anonymous',  options[:allow_anon],       nil,    nil,    nil,                options[:anon_failure] ],
            [ 'any user',   options[:allow_any_user],   :basic ],
            [ 'admin user', options[:allow_admin],      :admin ]
        ]

        unless options[:allow_groups].blank?
          if options[:allow_groups].is_a?(::String)
            options[:allow_groups] = options[:allow_groups].gsub(',', ';').split(';').map{|v| v.strip}
          end
          options[:allow_groups].each do |group|
            tests << [ "#{group} member", true, :basic, group ]
          end
        end

        unless options[:deny_groups].blank?
          if options[:deny_groups].is_a?(::String)
            options[:deny_groups] = options[:deny_groups].gsub(',', ';').split(';').map{|v| v.strip}
          end
          options[:deny_groups].each do |group|
            tests << [ "#{group} member", false, :basic, group ]
          end
        end

        all_code = ''

        tests.each do |(label, result, user, group, success_override, failure_override)|
          expected_result = result ? (success_override || options[:success]) : (failure_override || options[:failure])

          # build the code block
          test_code = "test \"should #{result ? '' : 'not '}allow access to #{action} for #{label}\" do\n"

          if user
            test_code += "  user = incline_users(#{user.inspect})\n"
            if group
              test_code += "  group = Incline::AccessGroup.find_or_create_by(name: #{group.inspect})\n"
              test_code += "  user.groups << group\n"
            end
            test_code += "  log_in_as user\n"
          end

          test_code += "  path = #{url_helper}\n"

          if params.blank?
            test_code += "  #{method}(path)\n"
          else
            test_code += "  #{method}(path, #{params})\n"
          end

          if expected_result.is_a?(::Symbol)
            test_code += "  assert_response #{expected_result.inspect}\n"
          else
            test_code += "  assert_redirected_to #{expected_result}\n"
          end

          test_code += "end\n"

          all_code += test_code

          unless options[:return_code]
            Incline::Log::debug test_code
            eval test_code
          end
        end

        options[:return_code] ? all_code : nil

      end

    end

    ##
    # Make sure main_app is available and working correctly in tests.
    def main_app
      Rails.application.class.routes.url_helpers
    end

    ##
    # Make sure incline is available and working correctly in tests.
    def incline
      Incline::Engine.routes.url_helpers
    end

    ##
    # Determines if a user is logged into the test session
    def is_logged_in?
      !session[:user_id].nil?
    end

    ##
    # Logs in a test user
    def log_in_as(user, options = {})
      password =      options[:password]    || 'Password123'
      remember_me =   options[:remember_me] || '1'
      if integration_test?
        post incline.login_path, session: { email: user.email, password: password, remember_me: remember_me }
      else
        session[:user_id] = user.id
      end
    end


    ##
    # Tests a specific field for presence validation.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #
    def assert_required(model, attribute, message = nil, regex = /can't be blank/i)
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      is_string = original_value.is_a?(::String)
      setter = :"#{attribute}="
      model.send setter, nil
      assert_not model.valid?, message ? (message + ': (nil)') : "Should not allow #{attribute} to be set to nil."
      assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      if is_string
        model.send setter, ''
        assert_not model.valid?, message ? (message + ": ('')") : "Should not allow #{attribute} to be set to empty string."
        assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
        model.send setter, '   '
        assert_not model.valid?, message ? (message + ": ('   ')") : "Should not allow #{attribute} to be set to blank string."
        assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      end
      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for maximum length restriction.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # max_length::
    #     This is the maximum valid length for the field.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #
    # options::
    #     This is a list of options for the validation.
    #     Currently :start_with and :end_with are recognized.
    #     Use :start_with to specify a prefix for the tested string.
    #     Use :end_with to specify a postfix for the tested string.
    #     This would be most useful when you value has to follow a format (eg - email address :end_with => '@example.com')
    #
    def assert_max_length(model, attribute, max_length, message = nil, regex = /is too long/i, options = {})
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="

      if message.is_a?(::Hash)
        options = message.merge(options || {})
        message = nil
      end

      if regex.is_a?(::Hash)
        options = regex.merge(options || {})
        regex = /is too long/i
      end

      pre = options[:start_with].to_s
      post = options[:end_with].to_s
      len = max_length - pre.length - post.length

      # try with maximum valid length.
      value = pre + ('a' * len) + post
      model.send setter, value
      assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

      # try with one extra character.
      value = pre + ('a' * (len + 1)) + post
      model.send setter, value
      assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."
      assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'

      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for maximum length restriction.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # min_length::
    #     This is the minimum valid length for the field.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #
    # options::
    #     This is a list of options for the validation.
    #     Currently :start_with and :end_with are recognized.
    #     Use :start_with to specify a prefix for the tested string.
    #     Use :end_with to specify a postfix for the tested string.
    #     This would be most useful when you value has to follow a format (eg - email address :end_with => '@example.com')
    #
    def assert_min_length(model, attribute, min_length, message = nil, regex = /is too short/i, options = {})
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="

      if message.is_a?(::Hash)
        options = message.merge(options || {})
        message = nil
      end

      if regex.is_a?(::Hash)
        options = regex.merge(options || {})
        regex = /is too short/i
      end

      pre = options[:start_with].to_s
      post = options[:end_with].to_s
      len = min_length - pre.length - post.length

      # try with minimum valid length.
      value = pre + ('a' * len) + post
      model.send setter, value
      assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

      # try with one extra character.
      value = pre + ('a' * (len - 1)) + post
      model.send setter, value
      assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."
      assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'

      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for uniqueness.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_, _errors_, and _save!_.
    #     The model will be saved to perform uniqueness testing.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # case_sensitive::
    #     This determines if changing case should change validation.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #
    #
    # alternate_scopes::
    #     This is also optional.  If provided the keys of the hash will be used to
    #     set additional attributes on the model.  When these attributes are changed to the alternate
    #     values, the model should once again be valid.
    #     The alternative scopes are processed one at a time and the original values are restored
    #     before moving onto the next scope.
    #     A special key :unique_fields, allows you to provide values for other unique fields in the model so they
    #     don't affect testing.  If the value of :unique_fields is not a hash, then it is put back into the
    #     alternate_scopes hash for testing.
    #
    def assert_uniqueness(model, attribute, case_sensitive = false, message = nil, regex = /has already been taken/i, alternate_scopes = {})
      setter = :"#{attribute}="
      original_value = model.send(attribute)

      assert model.valid?, 'Model should be valid to start.'

      if case_sensitive.is_a?(::Hash)
        alternate_scopes = case_sensitive.merge(alternate_scopes || {})
        case_sensitive = false
      end
      if message.is_a?(::Hash)
        alternate_scopes = message.merge(alternate_scopes || {})
        message = nil
      end
      if regex.is_a?(::Hash)
        alternate_scopes = regex.merge(alternate_scopes || {})
        regex = /has already been taken/i
      end

      model.save!
      copy = model.dup

      other_unique_fields = alternate_scopes.delete(:unique_fields)
      if other_unique_fields
        if other_unique_fields.is_a?(::Hash)
          other_unique_fields.each do |attr,val|
            setter = :"#{attr}="
            copy.send setter, val
          end
        else
          alternate_scopes[:unique_fields] = other_unique_fields
        end
      end

      assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
      assert copy.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : "Did not fail for expected reason"
      if original_value.is_a?(::String)
        unless case_sensitive
          copy.send(setter, original_value.upcase)
          assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
          assert copy.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : "Did not fail for expected reason"
          copy.send(setter, original_value.downcase)
          assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
          assert copy.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : "Did not fail for expected reason"
        end
      end

      unless alternate_scopes.blank?
        copy.send(setter, original_value)
        assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
        assert copy.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : "Did not fail for expected reason"
        alternate_scopes.each do |k,v|
          kset = :"#{k}="
          vorig = copy.send(k)
          copy.send(kset, v)
          assert_equal v, copy.send(k), message ? (message + ": (failed to set #{k})") : "Failed to set #{k}=#{v.inspect}."
          assert copy.valid?, message ? (message + ": !#{k}(#{v})") : "Duplicate model with #{k}=#{v.inspect} should be valid with #{attribute}=#{copy.send(attribute).inspect}."
          copy.send(kset, vorig)
          assert_equal vorig, copy.send(k), message ? (message + ": (failed to reset #{k})") : "Failed to reset #{k}=#{v.inspect}."
          assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
          assert copy.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : "Did not fail for expected reason"
        end
      end
    end

    ##
    # Tests a specific field for reCAPTCHA validation.
    #
    # During testing reCAPTCHA is disabled, but there is a special response that is expected.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #     The default value of nil uses two regular expressions to match the two failure cases.
    #
    def assert_recaptcha_validation(model, attribute, message = nil, regex = nil)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="

      # no response, just an ip address.
      model.send setter, '127.0.0.1'
      assert_not model.valid?, message ? (message + ': (accepted without response)') : 'Should not have accepted without response.'
      r = regex || /requires recaptcha challenge to be completed/i
      assert model.errors[:base].to_s =~ r, message ? (message + ': (error message)') : 'Did not fail for expected reason.'

      @item.recaptcha = '127.0.0.1|invalid'
      assert_not @item.valid?, message ? (message + ': (accepted invalid response)') : 'Should not have accepted invalid response.'
      r = regex || /invalid response from recaptcha challenge/i
      assert model.errors[:base].to_s =~ r, message ? (message + ': (error message)') : 'Did not fail for expected reason.'

      # since recaptcha is disabled for testing, the following string should validate.
      @item.recaptcha = '127.0.0.1|disabled'
      assert @item.valid?, message ? (message + ': (rejected valid response)') : 'Should have accepted valid response.'
    end

    ##
    # Tests a specific field for email verification.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #
    def assert_email_validation(model, attribute, message = nil, regex = /is not a valid email address/i)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="
      orig = model.send attribute

      valid = %w(
        user@example.com
        USER@foo.COM
        A_US-ER@foo.bar.org
        first.last@foo.jp
        alice+bob@bax.cn
      )

      invalid = %w(
        user@example,com
        user_at_foo.org
        user@example.
        user@example.com.
        foo@bar_baz.com
        foo@bar+baz.com
        @example.com
        user@
        user
        user@..com
        user@example..com
        user@.example.com
        user@@example.com
        user@www@example.com
      )

      valid.each do |addr|
        model.send setter, addr
        assert model.valid?, message ? (message + ': (rejected valid address)') : "Should have accepted #{addr.inspect}."
      end

      invalid.each do |addr|
        model.send setter, addr
        assert_not model.valid?, message ? (message + ': (accepted invalid address)') : "Should have rejected #{addr.inspect}."
        assert model.errors[attribute].to_s =~ regex, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      end

      model.send setter, orig
      assert model.valid?, message ? (message + ': (rejected original value)') : "Should have accepted original value of #{orig.inspect}."

    end


    ##
    # Tests a specific field for IP address verification.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # mask::
    #     This can be one of :allow_mask, :require_mask, or :deny_mask.  The default is :allow_mask.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #     The default value is nil to test for the various default messages.
    #
    def assert_ip_validation(model, attribute, mask = :allow_mask, message = nil, regex = nil)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="
      orig = model.send attribute

      valid = %w(
          0.0.0.0
          1.2.3.4
          10.20.30.40
          255.255.255.255
          10:20::30:40
          ::1
          1:2:3:4:5:6:7:8
          A:B:C:D:E:F::
      )

      invalid = %w(
          localhost
          100.200.300.400
          12345::abcde
          1.2.3.4.5
          1.2.3
          0
          1:2:3:4:5:6:7:8:9:0
          a:b:c:d:e:f:g:h
      )

      valid.each do |addr|
        if mask == :require_mask
          if addr.index(':')
            addr += '/128'
          else
            addr += '/32'
          end
        end
        model.send setter, addr
        assert model.valid?, message ? (message + ': (rejected valid address)') : "Should have accepted #{addr.inspect}."
      end

      r = regex ? regex : /is not a valid ip address/i
      invalid.each do |addr|
        if mask == :require_mask
          if addr.index(':')
            addr += '/128'
          else
            addr += '/32'
          end
        end
        model.send setter, addr
        assert_not model.valid?, message ? (message + ': (accepted invalid address)') : "Should have rejected #{addr.inspect}."
        assert model.errors[attribute].to_s =~ r, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      end

      if mask == :allow_mask || mask == :require_mask
        address = '127.0.0.0/8'
        model.send setter, address
        assert model.valid?, message ? (message + ': (rejected masked address)') : "Should have accepted #{address.inspect}."
      end

      if mask == :allow_mask || mask == :deny_mask
        address = '127.0.0.1'
        model.send setter, address
        assert model.valid?, message ? (message + ': (rejected unmasked address)') : "Should have accepted #{address.inspect}."
      end

      if mask == :require_mask
        r = regex ? regex : /must contain a mask/i
        address = '127.0.0.1'
        model.send setter, address
        assert_not model.valid?, message ? (message + ': (accepted unmasked address)') : "Should have rejected #{address.inspect} for no mask."
        assert model.errors[attribute].to_s =~ r, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      end

      if mask == :deny_mask
        r = regex ? regex : /must not contain a mask/i
        address = '127.0.0.0/8'
        model.send setter, address
        assert_not model.valid? message ? (message + ': (accepted masked address)') : "Should have rejected #{address.inspect} for mask."
        assert model.errors[attribute].to_s =~ r, message ? (message + ': (error message)') : 'Did not fail for expected reason.'
      end

      model.send setter, orig
      assert model.valid?, message ? (message + ': (rejected original value)') : "Should have accepted original value of #{orig.inspect}."
    end

    ##
    # Tests a specific field for safe name verification.
    #
    # model::
    #     This must respond to _attribute_ and _attribute=_ as well as _valid?_ and _errors_.
    #
    # attribute::
    #     This must provide the name of a valid attribute in the model.
    #
    # length::
    #     The length of the string to test.  Must be greater than 2.  Default is 6.
    #
    # message::
    #     This is optional, but if provided it will be postfixed with the failure reason.
    #
    # regex::
    #     This is the regex to match against the error message to ensure that the failure is for the correct reason.
    #     The default value is nil to test for the various default messages.
    #
    def assert_safe_name_validation(model, attribute, length = 6, message = nil, regex = nil)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="
      orig = model.send attribute

      assert length > 2, message ? (message + ': (field is too short to test)') : 'Requires a field length greater than 2 to perform tests.'

      # valid tests.
      mid_length = length - 2
      mid = ''    # _z_z_z_z_z_
      while mid.length < mid_length
        if mid.length + 1 < mid_length
          mid += '_z'
        else
          mid += '_'
        end
      end

      [
          'a' * length,
          'a' + ('1' * (length - 1)),
          'a' + mid + 'a',
          'a' + mid + '1'
      ].each do |val|
        model.send setter, val
        assert model.valid?, message ? (message + ': (rejected valid string)') : "Should have accepted #{val.inspect}."
        val.upcase!
        model.send setter, val
        assert model.valid?, message ? (message + ': (rejected valid string)') : "Should have accepted #{val.inspect}."
      end

      # invalid tests.
      {
          '_' + ('a' * (length - 1)) => /must start with a letter/i,
          '1' + ('a' * (length - 1)) => /must start with a letter/i,
          ('a' * (length - 1)) + '_' => /must not end with an underscore/i,
          ('a' * (length - 2)) + '-' + 'a' => /must contain only letters, numbers, and underscore/i,
          ('a' * (length - 2)) + '#' + 'a' => /must contain only letters, numbers, and underscore/i,
          ('a' * (length - 2)) + ' ' + 'a' => /must contain only letters, numbers, and underscore/i
      }.each do |val, reg|
        r = regex ? regex : reg
        model.send setter, val
        assert_not model.valid?, message ? (message + ': (accepted invalid string)') : "Should have rejected #{val.inspect}."
        assert model.errors[attribute].to_s =~ r, message ? (message + ': (error message)') : "Did not fail for expected reason on #{val.inspect}."
      end

      model.send setter, orig
      assert model.valid?, message ? (message + ': (rejected original value)') : "Should have accepted original value of #{orig.inspect}."
    end

    ##
    # Includes the class methods into the including object.
    def self.included(base)
      base.extend ClassMethods
    end

    private

    # returns true inside an integration test
    def integration_test?
      defined?(post_via_redirect)
    end


  end
end

ActiveSupport::TestCase.include Incline::Extensions::TestCase