require 'test_helper'

module Incline
  class UsersSignupTest < ActionDispatch::IntegrationTest

    def setup
      @routes = Incline::Engine.routes
      @valid_params = self.class.valid_params
      ActionMailer::Base.deliveries.clear
    end

    def self.valid_params
      {
          name: 'Valid User',
          email: 'valid@example.com',
          password: 'Password321',
          password_confirmation: 'Password321',
          recaptcha: Incline::Recaptcha::DISABLED
      }
    end

    # should not allow when logged in (except admins can create other users)
    access_tests_for :new,
                     controller: 'users',
                     url_helper: 'incline.signup_path',
                     allow_anon: true,
                     allow_any_user: false,
                     allow_admin: true,
                     failure: 'incline.user_path(user)'

    access_tests_for :create,
                     controller: 'users',
                     url_helper: 'incline.signup_path',
                     allow_anon: true,
                     allow_any_user: false,
                     allow_admin: true,
                     success: '(system_admin? ? incline.users_path : main_app.root_path)',
                     failure: 'incline.user_path(user)',
                     create_params: { user: valid_params }

    test 'signup template' do
      get incline.signup_path
      assert_template 'incline/users/new'
      assert_select 'form[action=?]', incline.signup_path
      assert_select '#user_name'
      assert_select '#user_email'
      assert_select '#user_password'
    end

    test 'require name' do
      # no name
      get incline.signup_path
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(name: '')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Name can't be blank/
      assert_select 'div.field_with_errors input[id=?]', 'user_name'
    end

    test 'require valid email' do
      # no email
      get incline.signup_path
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(email: '')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Email can't be blank/
      assert_select 'div.field_with_errors input[id=?]', 'user_email'

      # invalid email
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(email: 'admin@localhost')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Email is not a valid email address/
      assert_select 'div.field_with_errors input[id=?]', 'user_email'
    end

    test 'require password and confirmation' do
      # no password
      get incline.signup_path
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(password: '')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Password can't be blank/
      assert_select 'div.field_with_errors input[id=?]', 'user_password'

      # no password confirmation
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(password_confirmation: '')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Password confirmation doesn't match Password/
      assert_select 'div.field_with_errors input[id=?]', 'user_password_confirmation'
    end

    test 'require reCAPTCHA' do
      # no reCAPTCHA challenge
      get incline.signup_path
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(recaptcha: '')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Recaptcha can't be blank/

      # invalid reCAPTCHA challenge
      assert_no_difference 'Incline::User.count' do
        post incline.signup_path, user: @valid_params.merge(recaptcha: '0.0.0.0')
      end
      assert_template 'incline/users/new'
      assert_select 'div#error_explanation', /Requires reCAPTCHA challenge to be completed/
    end

    test 'valid signup' do
      # valid signup
      get incline.signup_path
      assert_difference 'Incline::User.count', 1 do
        post incline.signup_path, user: @valid_params
      end
      assert_not is_logged_in?
      assert_equal 1, ActionMailer::Base.deliveries.size
      user = assigns(:user)
      assert_not user.activated?
      token = user.activation_token
      assert_not_nil token

      # try logging in before activation.
      log_in_as user, password: @valid_params[:password]
      assert_not is_logged_in?

      # invalid activation token
      get incline.edit_account_activation_path('invalid-token', email: user.email)
      assert_not is_logged_in?
      assert_not user.reload.activated?

      # valid activation token
      get incline.edit_account_activation_path(token, email: user.email)
      assert user.reload.activated?
      follow_redirect!
      assert_template 'incline/users/show'
      assert is_logged_in?
    end

  end
end
