require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  test 'invalid signup information' do
    get incline.signup_path
    assert_select 'form[action=?]', incline.signup_path
    assert_no_difference 'Incline::User.count' do
      post incline.signup_path,
           user: {
               name:                   '',
               email:                  'user@invalid',
               password:               'foo',
               password_confirmation:  'bar'
           }
    end
    assert_template 'incline/users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end

  test 'valid signup information' do
    get incline.signup_path
    assert_difference 'Incline::User.count', 1 do
      post incline.signup_path, user: {
          name:                   'Example User',
          email:                  'new-user@example.com',
          password:               'password',
          password_confirmation:  'password'
      }
    end
    assert_not is_logged_in?
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    token = user.activation_token
    assert_not_nil token
    # try logging in before activation
    log_in_as user
    assert_not is_logged_in?
    # invalid activation token
    get incline.edit_account_activation_url('invalid token', email: user.email)
    assert_not is_logged_in?
    assert_not user.reload.activated?
    # valid activation token
    get incline.edit_account_activation_url(token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'incline/users/show'
    assert is_logged_in?
  end

end
