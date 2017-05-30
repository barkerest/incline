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

    test 'should redirect edit when not logged in' do
      get incline.edit_user_path(@user)
      assert_redirected_to incline.login_path
    end

    test 'should redirect update when not logged in' do
      patch incline.user_path(@user), user: { name: @user.name, email: @user.email }
      assert_redirected_to incline.login_path
    end

    test 'should redirect edit when logged in as wrong user' do
      log_in_as @other_user
      get incline.edit_user_path(@user)
      assert_redirected_to main_app.root_path
    end

    test 'should redirect update when logged in as wrong user' do
      log_in_as @other_user
      patch incline.user_path(@user), user: { name: @user.name, email: @user.email }
      assert_redirected_to main_app.root_path
    end

    test 'should redirect destroy when not logged in' do
      assert_no_difference 'Incline::User.count' do
        delete incline.user_path(@disabled_user)
      end
      assert_redirected_to incline.login_path
    end

    test 'should redirect destroy when logged in as non-admin' do
      log_in_as @other_user
      assert_no_difference 'Incline::User.count' do
        delete incline.user_path(@disabled_user)
      end
      assert_redirected_to main_app.root_path
    end

    test 'should allow destroy when logged in as admin' do
      log_in_as @admin
      assert_difference 'Incline::User.count', -1 do
        delete incline.user_path(@disabled_user)
      end
      assert_redirected_to incline.users_path
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

    test 'should not allow the admin attribute to be edited via web' do
      log_in_as @other_user
      assert_not @other_user.system_admin?
      patch incline.user_path(@other_user), user: { password: 'password', password_confirmation: 'password', system_admin: '1' }
      assert_not @other_user.reload.system_admin?
    end

    test 'should redirect disable when not logged in' do
      assert_no_difference 'Incline::User.enabled.count' do
        get incline.disable_user_path(@user)
      end
      assert_redirected_to incline.login_path
      assert_no_difference 'Incline::User.enabled.count' do
        patch incline.disable_user_path(@user), disable_info: { reason: 'As a test' }
      end
      assert_redirected_to incline.login_path
    end

    test 'should redirect disable when logged in as non-admin' do
      log_in_as @other_user
      assert_no_difference 'Incline::User.enabled.count' do
        get incline.disable_user_path(@user)
      end
      assert_redirected_to main_app.root_path
      assert_no_difference 'Incline::User.enabled.count' do
        patch incline.disable_user_path(@user), disable_info: { reason: 'As a test' }
      end
      assert_redirected_to main_app.root_path
    end

    test 'should redirect enable when not logged in' do
      assert_no_difference 'Incline::User.enabled.count' do
        patch incline.enable_user_path(@disabled_user)
      end
      assert_redirected_to incline.login_path
    end

    test 'should redirect enable when logged in as non-admin' do
      log_in_as @other_user
      assert_no_difference 'Incline::User.enabled.count' do
        patch incline.enable_user_path(@disabled_user)
      end
      assert_redirected_to main_app.root_path
    end

    test 'should disable user for admins' do
      log_in_as @admin
      assert_no_difference 'Incline::User.enabled.count' do
        get incline.disable_user_path(@other_user)
      end
      assert_template 'incline/users/disable_confirm'
      assert_difference 'Incline::User.enabled.count', -1 do
        patch incline.disable_user_path(@other_user), disable_info: { reason: 'As a test' }
      end
      assert_redirected_to incline.users_path
    end

    test 'should enable user for admins' do
      log_in_as @admin
      assert_difference 'Incline::User.enabled.count', 1 do
        patch incline.enable_user_path(@disabled_user)
      end
      assert_redirected_to incline.users_path
    end

    test 'unsuccessful edit' do
      get incline.edit_user_path(@user)
      assert_redirected_to incline.login_path
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
