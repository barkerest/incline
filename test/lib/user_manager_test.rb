require 'test_helper'

class UserManagerTest < ::ActiveSupport::TestCase
  
  class MyAuthEngine < ::Incline::AuthEngineBase
    def initialize(options = {})
      @valid_password = options[:valid_password] || 'password'
    end
    
    def authenticate(email, password, client_ip)
      return nil unless password == @valid_password
      ::Incline::User.find_by(email: email)
    end
  end
  
  def setup
    @manager = ::Incline::UserManager.new valid_password: 'super-secret'
    @user = incline_users(:one)
  end
  
  test 'password should be based on database value' do
    assert_nil @manager.authenticate(@user.email, 'super-secret', '0.0.0.0')
    assert @manager.authenticate(@user.email, 'Password123', '0.0.0.0')
  end
  
  test 'password should be based on auth engine' do
    @manager.register_auth_engine ::UserManagerTest::MyAuthEngine, 'example.com'
    assert @manager.authenticate(@user.email, 'super-secret', '0.0.0.0')
    assert_nil @manager.authenticate(@user.email, 'Password123', '0.0.0.0')
  end
  
  test 'default instance also works with auth engine' do
    assert ::Incline::UserManager.authenticate(@user.email, 'Password123', '0.0.0.0')
    assert_nil ::Incline::UserManager.authenticate(@user.email, 'password', '0.0.0.0')
    begin
      ::Incline::UserManager.register_auth_engine(::UserManagerTest::MyAuthEngine, 'example.com')
      assert_nil ::Incline::UserManager.authenticate(@user.email, 'Password123', '0.0.0.0')
      assert ::Incline::UserManager.authenticate(@user.email, 'password', '0.0.0.0')
    ensure
      ::Incline::UserManager.clear_auth_engine('example.com')
    end
    
  end
  
  
  
end