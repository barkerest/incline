require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  test 'should get root_path' do
    get root_path
    assert_response :success
    assert_select 'title', full_title
    assert_select 'div.jumbotron'
    assert_select 'a[href=?]', root_path, count: 2
    assert_select 'a[href=?]', incline.login_path, count: 1
    assert_select 'a[href=?]', incline.contact_path, count: 1
  end


end
