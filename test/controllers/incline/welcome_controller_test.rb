require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest

  test 'should get root_path' do
    get root_path
    assert_response :success
    # assert_select 'title', full_title
    assert_select 'div.jumbotron'
  end

end
