require 'test_helper'

module Incline
  class UsersLoginTest < ActionDispatch::IntegrationTest

    def setup
      @routes = Incline::Engine.routes
      @user = Incline::User.find_by(email: valid_creds[:email])
    end

    def self.valid_creds
      {
          email: 'george@example.com',
          password: 'Password123'
      }
    end

    def valid_creds
      self.class.valid_creds
    end

    # to get the login form, you must not be logged in.
    access_tests_for :new,
                     controller: 'sessions',
                     url_helper: 'incline.login_path',
                     allow_anon: true,
                     allow_any_user: false,
                     allow_admin: false,
                     failure: 'incline.user_path(user)'

    # to login, you must not be logged in.
    access_tests_for :create,
                     controller: 'sessions',
                     url_helper: 'incline.login_path',
                     allow_anon: true,
                     allow_any_user: false,
                     allow_admin: false,
                     create_params: { session: valid_creds },
                     success: 'incline.user_path(@user)',   # instance var
                     failure: 'incline.user_path(user)'     # local var

    test 'login template' do
      get incline.login_path
      assert_template 'incline/sessions/new'
      assert_select '#session_email'
      assert_select '#session_password'
      assert_select 'a[href=?]', incline.signup_path
      assert_select 'a[href=?]', incline.new_password_reset_path
    end

    test 'login with invalid information' do
      get incline.login_path
      assert_template 'incline/sessions/new'
      post incline.login_path, session: { email: '', password: '' }
      assert_template 'incline/sessions/new'
      assert_not flash.empty?
      get main_app.root_path
      assert flash.empty?
      assert_select 'a[href=?]', incline.login_path
      assert_select 'a[href=?]', incline.logout_path, count: 0
    end

    test 'login with valid information followed by logout' do
      get incline.login_path
      post incline.login_path, session: valid_creds
      assert is_logged_in?
      assert_redirected_to @user
      follow_redirect!
      assert_template 'incline/users/show'
      assert_select 'a[href=?]', incline.login_path, count: 0
      assert_select 'a[href=?]', incline.logout_path
      assert_select 'a[href=?]', incline.user_path(@user)
      delete incline.logout_path
      assert_not is_logged_in?
      assert_redirected_to main_app.root_path
      # simulate clicking 'log out' a second time.
      delete incline.logout_path
      assert_redirected_to main_app.root_path
      follow_redirect!
      assert_select 'a[href=?]', incline.login_path
      assert_select 'a[href=?]', incline.logout_path, count: 0
      assert_select 'a[href=?]', incline.user_path(@user), count: 0
    end

    test 'login with disabled account' do
      @user = incline_users(:disabled)
      get incline.login_path
      post incline.login_path, session: { email: @user.email, password: valid_creds[:password] }
      assert_template 'incline/sessions/new'
      assert_not flash.empty?
    end

    test 'login with remembering' do
      log_in_as @user, remember_me: '1'
      assert_not_nil cookies[user_token_cookie.to_s]
      assert_equal assigns(:user).remember_token, cookies[user_token_cookie.to_s]
    end

    test 'login without remembering' do
      log_in_as @user, remember_me: '0'
      assert_nil cookies[user_token_cookie.to_s]
    end

  end
end
