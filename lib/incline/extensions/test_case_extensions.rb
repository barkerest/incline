module Incline
  ##
  # Adds some extra assertions and methods for use in tests.
  module TestCaseExtensions

    ##
    # Determines if a user is logged into the test session
    def is_logged_in?
      !session[:user_sid].nil?
    end

    ##
    # Logs in a test user
    def log_in_as(user, options = {})
      password = options[:password]       || 'password123'
      remember_me = options[:remember_me] || '1'
      if integration_test?
        post incline.login_path, session: { email: user.email, password: password, remember_me: remember_me }
      else
        session[:user_sid] = user.sid
      end
    end

    ##
    # Runs date tests against a field.
    def run_date_field_tests(item, attr, can_be_nil = true)
      eq = "#{attr}="
      pre = "#{attr}_before_type_cast"

      if can_be_nil
        item.send(eq, nil)
        assert_equal nil, item.send(attr), "#{attr} of #{item.class} did not return nil after being set."
        assert_equal nil, item.send(pre), "#{pre} of #{item.class} did not return nil after being set."
      end

      dt = Date.today
      dts = dt.strftime("%m/%d/%Y")
      dtf = dt.strftime("%Y-%m-%d")
      item.send(eq, dt)
      assert_equal Date.parse(dtf), item.send(attr), "#{attr} of #{item.class} did not return #{dtf}."
      assert_equal dts, item.send(pre), "#{pre} of #{item.class} did not return '#{dts}'."

      dt = Time.zone.now
      dts = dt.strftime("%m/%d/%Y")
      dtf = dt.strftime("%Y-%m-%d")
      item.send(eq, dt)
      assert_equal Date.parse(dtf), item.send(attr), "#{attr} of #{item.class} did not return #{dtf}."
      assert_equal dts, item.send(pre), "#{pre} of #{item.class} did not return '#{dts}'."

      dt = "10/11/2015"
      dtf = "2015-10-11"
      item.send(eq, dt)
      assert_equal Date.parse(dtf), item.send(attr), "#{attr} of #{item.class} did not return #{dtf}."
      assert_equal dt, item.send(pre), "#{pre} of #{item.class} did not return '#{dt}'."
    end

    ##
    # Tests a specific field for presence validation.
    #
    # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
    #
    # +attribute+ must provide the name of a valid attribute in the model.
    #
    # +message+ is optional, but if provided it will be postfixed with the failure reason.
    def assert_required(model, attribute, message = nil)
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      is_string = original_value.is_a?(String)
      setter = :"#{attribute}="
      model.send setter, nil
      assert_not model.valid?, message ? (message + ': (nil)') : "Should not allow #{attribute} to be set to nil."
      if is_string
        model.send setter, ''
        assert_not model.valid?, message ? (message + ": ('')") : "Should not allow #{attribute} to be set to empty string."
        model.send setter, '   '
        assert_not model.valid?, message ? (message + ": ('   ')") : "Should not allow #{attribute} to be set to blank string."
      end
      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for maximum length restriction.
    #
    # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
    #
    # +attribute+ must provide the name of a valid attribute in the model.
    #
    # +max_length+ is the maximum valid length for the field.
    #
    # +message+ is optional, but if provided it will be postfixed with the failure reason.
    def assert_max_length(model, attribute, max_length, message = nil, options = {})
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="

      if message.is_a?(Hash)
        options = message.merge(options || {})
        message = nil
      end

      pre = options[:start].to_s
      post = options[:end].to_s
      len = max_length - pre.length - post.length

      # try with maximum valid length.
      value = pre + ('a' * len) + post
      model.send setter, value
      assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

      # try with one extra character.
      value = pre + ('a' * (len + 1)) + post
      model.send setter, value
      assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."

      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for maximum length restriction.
    #
    # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
    #
    # +attribute+ must provide the name of a valid attribute in the model.
    #
    # +max_length+ is the maximum valid length for the field.
    #
    # +message+ is optional, but if provided it will be postfixed with the failure reason.
    def assert_min_length(model, attribute, min_length, message = nil, options = {})
      original_value = model.send(attribute)
      assert model.valid?, 'Model should be valid to start.'
      setter = :"#{attribute}="

      if message.is_a?(Hash)
        options = message.merge(options || {})
        message = nil
      end

      pre = options[:start].to_s
      post = options[:end].to_s
      len = max_length - pre.length - post.length

      # try with minimum valid length.
      value = pre + ('a' * len) + post
      model.send setter, value
      assert model.valid?, message ? (message + ": !(#{value.length})") : "Should allow a string of #{value.length} characters."

      # try with one extra character.
      value = pre + ('a' * (len - 1)) + post
      model.send setter, value
      assert_not model.valid?, message ? (message + ": (#{value.length})") : "Should not allow a string of #{value.length} characters."

      model.send setter, original_value
      assert model.valid?, message ? (message + ": !(#{original_value.inspect})") : "Should allow #{attribute} to be set back to '#{original_value.inspect}'."
    end

    ##
    # Tests a specific field for uniqueness.
    #
    # +model+ must respond to _attribute_ and _attribute=_ as well as _valid?_.
    # The model will be saved to perform uniqueness testing.
    #
    # +attribute+ must provide the name of a valid attribute in the model.
    #
    # +case_sensitive+ determines if changing case should change validation.
    #
    # +message+ is optional, but if provided it will be postfixed with the failure reason.
    #
    # +alternate_scopes+ is also optional.  If provided the keys of the hash will be used to
    # set additional attributes on the model.  When these attributes are changed to the alternate
    # values, the model should once again be valid.
    def assert_uniqueness(model, attribute, case_sensitive = false, message = nil, alternate_scopes = {})
      setter = :"#{attribute}="
      original_value = model.send(attribute)

      assert model.valid?, 'Model should be valid to start.'

      if case_sensitive.is_a?(Hash)
        alternate_scopes = case_sensitive.merge(alternate_scopes || {})
        case_sensitive = false
      end
      if message.is_a?(Hash)
        alternate_scopes = message.merge(alternate_scopes || {})
        message = nil
      end

      copy = model.dup
      model.save!

      assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
      unless case_sensitive
        copy.send(setter, original_value.to_s.upcase)
        assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
        copy.send(setter, original_value.to_s.downcase)
        assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
      end

      unless alternate_scopes.blank?
        copy.send(setter, original_value)
        assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."
        alternate_scopes.each do |k,v|
          kset = :"#{k}="
          vorig = copy.send(k)
          copy.send(kset, v)
          assert copy.valid?, message ? (message + ": !#{k}(#{v})") : "Duplicate model with #{k}=#{v.inspect} should be valid with #{attribute}=#{copy.send(attribute).inspect}."
          copy.send(kset, vorig)
          assert_not copy.valid?, message ? (message + ": (#{copy.send(attribute).inspect})") : "Duplicate model with #{attribute}=#{copy.send(attribute).inspect} should not be valid."      end
      end
    end


    private

    # returns true inside an integration test
    def integration_test?
      defined?(post_via_redirect)
    end


  end
end

ActiveSupport::TestCase.include Incline::TestCaseExtensions