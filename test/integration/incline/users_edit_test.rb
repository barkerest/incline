require 'test_helper'

module Incline
  class UsersEditTest < ActionDispatch::IntegrationTest
    def setup
      @user = incline_users(:one)
      @other_user = incline_users(:two)
      @admin = incline_users(:admin)
      @disabled_user = incline_users(:disabled)
      @recent_user = incline_users(:recently_disabled)
    end

    # only admin can view random users.
    access_tests_for :show,
                     controller: 'users',
                     url_helper: 'incline.user_path(@user)',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    # and users can view themselves.
    test 'user should be able to show self' do
      log_in_as @user
      get incline.user_path(@user)
      assert_response :success
    end

    # only admin can edit random users.
    access_tests_for :edit,
                     controller: 'users',
                     url_helper: 'incline.edit_user_path(@user)',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    # and users can edit themselves.
    test 'user can edit self' do
      log_in_as @user
      get incline.edit_user_path(@user)
      assert_template 'incline/users/edit'
      assert_select 'form[action=?]', incline.user_path(@user)
      assert_select '#user_name'
      assert_select '#user_email'
      assert_select '#user_password'
    end

    # only admin can update random users.
    access_tests_for :update,
                     controller: 'users',
                     url_helper: 'incline.user_path(@user)',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     update_params: '{ user: { name: @user.name, email: @user.email } }',
                     success: '(system_admin? ? incline.users_path : incline.user_path(@user))'

    # and users can update themselves.
    test 'user can update self' do
      log_in_as @user
      patch incline.user_path(@user), user: { name: @user.name, email: @user.email }
      assert_redirected_to incline.user_path(@user)
    end


    # only admin can destroy users.
    access_tests_for :destroy,
                     controller: 'users',
                     url_helper: 'incline.user_path(@disabled_user)',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     success: 'incline.users_path'

    test 'user count should change when destroyed' do
      log_in_as @admin
      assert_difference 'Incline::User.count', -1 do
        delete incline.user_path(@disabled_user)
      end
    end

    test 'should not destroy recently disabled users' do
      log_in_as @admin
      assert_no_difference 'Incline::User.count' do
        delete incline.user_path(@recent_user)
      end
      assert_redirected_to incline.users_path
    end

    test 'should not destroy active users' do
      log_in_as @admin
      assert_no_difference 'Incline::User.count' do
        delete incline.user_path(@user)
      end
      assert_redirected_to incline.users_path
    end

    # only admin can disable users.
    access_tests_for :disable_confirm,
                     controller: 'users',
                     url_helper: 'incline.disable_user_path(@user)',
                     method: 'get',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :disable,
                     controller: 'users',
                     url_helper: 'incline.disable_user_path(@user)',
                     method: 'patch',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     success: 'incline.users_path',
                     disable_params: { disable_info: { reason: 'As a test' } }

    test 'enabled count should change when disabled' do
      log_in_as @admin
      assert_difference 'Incline::User.enabled.count', -1 do
        patch incline.disable_user_path(@other_user), disable_info: { reason: 'As a test' }
      end
    end

    access_tests_for :enable,
                     controller: 'users',
                     url_helper: 'incline.enable_user_path(@recent_user)',
                     method: 'patch',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     success: 'incline.users_path'

    test 'enabled cound should change when enabled' do
      log_in_as @admin
      assert_difference 'Incline::User.enabled.count', 1 do
        patch incline.enable_user_path(@recent_user)
      end
    end




    test 'should not allow the admin attribute to be edited via web' do
      log_in_as @other_user
      assert_not @other_user.system_admin?
      patch incline.user_path(@other_user), user: { password: 'password', password_confirmation: 'password', system_admin: '1' }
      assert_not @other_user.reload.system_admin?
    end

    test 'unsuccessful edit' do
      log_in_as(@user)
      get incline.edit_user_path(@user)
      assert_template 'incline/users/edit'
      patch incline.user_path(@user), user: { name: '', email: 'foo@invalid', password: 'foo', password_confirmation: 'baz' }
      assert_template 'incline/users/edit'
      assert_select 'div#error_explanation'
    end

    test 'successful edit with friendly forwarding' do
      get incline.edit_user_path(@user)
      assert_redirected_to incline.login_path
      log_in_as(@user)
      assert_redirected_to incline.edit_user_path(@user)
      name = 'Foo Bar'
      email = 'foo@bar.com'
      pwd = ''
      patch incline.user_path(@user), user: { name: name, email: email, password: pwd, password_confirmation: pwd }
      assert_not flash.empty?
      assert_redirected_to @user
      @user.reload
      assert_equal name, @user.name
      assert_equal email, @user.email
      pwd = 'new-password'
      patch incline.user_path(@user), user: { name: name, email: email, password: pwd, password_confirmation: pwd }
      assert_not flash.empty?
      assert_redirected_to @user
      @user.reload
      assert @user.authenticate(pwd)
    end
  end
end
