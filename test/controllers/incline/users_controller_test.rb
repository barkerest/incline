require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest

  test 'should get signup_path' do
    get incline.signup_path
    assert_response :success

  end

end