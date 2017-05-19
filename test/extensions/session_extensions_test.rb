require 'test_helper'

class SessionExtensionsTest < ActionDispatch::IntegrationTest

  VIEW_METHODS = [
      :user_id_cookie,
      :user_token_cookie,
      :current_user,
      :current_user?,
      :logged_in?,
      :system_admin?
  ]

  CONTROLLER_METHODS = [
      :log_in,
      :log_out,
      :remember,
      :forget
  ]

  # A broken mailer just to check for methods.
  class TestMailer < ActionMailer::Base

    def self.create_instance
      new
    end

  end

  test 'test has correct methods' do
    VIEW_METHODS.each do |m|
      assert respond_to?(m), "Test should respond to #{m.inspect}."
    end
    CONTROLLER_METHODS.each do |m|
      assert_not respond_to?(m), "Test should not respond to #{m.inspect}."
    end
  end

  test 'view has correct methods' do
    view = ActionView::Base.new
    VIEW_METHODS.each do |m|
      assert view.respond_to?(m), "View should respond to #{m.inspect}."
    end
    CONTROLLER_METHODS.each do |m|
      assert_not view.respond_to?(m), "View should not respond to #{m.inspect}."
    end
  end

  test 'controller has correct methods' do
    ctrlr = ActionController::Base.new
    VIEW_METHODS.each do |m|
      assert ctrlr.respond_to?(m), "Controller should respond to #{m.inspect}."
    end
    CONTROLLER_METHODS.each do |m|
      assert ctrlr.respond_to?(m), "Controller should respond to #{m.inspect}."
    end
  end

  test 'mailer has correct methods' do
    mailer = TestMailer.create_instance
    VIEW_METHODS.each do |m|
      assert mailer.respond_to?(m), "Mailer should respond to #{m.inspect}."
    end
    CONTROLLER_METHODS.each do |m|
      assert_not mailer.respond_to?(m), "Mailer should not respond to #{m.inspect}."
    end
  end

end