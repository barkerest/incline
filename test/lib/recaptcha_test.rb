require 'test_helper'

class RecaptchaTest < ActiveSupport::TestCase
  
  test 'should be disabled by default in test mode' do
    assert ::Incline::Recaptcha.disabled?
  end
  
  test 'should enable for testing' do
    assert_not ::Incline::Recaptcha.send :enabled_for_testing?
    ::Incline::Recaptcha.send(:enable_for_testing) do
      assert ::Incline::Recaptcha.send :enabled_for_testing?
    end
    assert_not ::Incline::Recaptcha.send :enabled_for_testing?
  end
  
  test 'when configured should allow testing' do
    skip if ::Incline::Recaptcha.public_key.blank? || ::Incline::Recaptcha.private_key.blank?

    assert ::Incline::Recaptcha.disabled?
    ::Incline::Recaptcha.send(:enable_for_testing) do
      assert_not ::Incline::Recaptcha.disabled?
    end
    assert ::Incline::Recaptcha.disabled?
  end
  
  test 'add should work appropriately' do
    assert ::Incline::Recaptcha.add.blank?

    ::Incline::Recaptcha.send(:enable_for_testing, 'my_site_key', 'my_secret_key') do
      html = ::Incline::Recaptcha.add
      assert_not html.blank?
      assert html =~ /my_site_key/
      assert_nil html =~ /my_secret_key/
    end
  end
  
  test 'verify should work appropriately' do
    
    assert_raises ::ArgumentError do
      ::Incline::Recaptcha.verify
    end
    
    
    # fake request class.
    req = Class.new do
      def params
        @params ||= { 'g-recaptcha-response' => ::Incline::Recaptcha::DISABLED.partition('|')[2] }
      end
      def remote_ip
        @remote_ip ||= ::Incline::Recaptcha::DISABLED.partition('|')[0]
      end
    end.new
    
    # and standard parameters.
    rem_ip, _, resp = ::Incline::Recaptcha::DISABLED.partition('|')

    # these are all valid method calls.
    assert ::Incline::Recaptcha.verify(req)
    assert ::Incline::Recaptcha.verify(request: req)
    assert ::Incline::Recaptcha.verify(remote_ip: rem_ip, response: resp)
    
    req.params['g-recaptcha-response'] = 'something-invalid'
    
    # these should all fail
    assert_not ::Incline::Recaptcha.verify(req)
    assert_not ::Incline::Recaptcha.verify(request: req)
    assert_not ::Incline::Recaptcha.verify(remote_ip: rem_ip, response: 'something-invalid')
    
  end
  
  
  
  
end