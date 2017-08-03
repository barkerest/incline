require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  
  # 2017-08-03: root path should be changeable by actual app. remove jumbotron check and instead do some link checks that should always be present.
  test 'should get root_path' do
    get root_path
    assert_response :success
    assert_select 'title', full_title
    assert_select 'a[href=?]', main_app.root_path, count: 2
    assert_select 'a[href=?]', incline.login_path, count: 1
    assert_select 'a[href=?]', incline.contact_path, count: 1
  end


end
