require 'test_helper'

module Incline
  class PasswordResetRequestTest < ActiveSupport::TestCase

    def setup
      @item = Incline::PasswordResetRequest.new(
          email: 'user@example.com',
          recaptcha: Incline::Recaptcha::DISABLED
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require email' do
      assert_required @item, :email
    end

    test 'should require recaptcha' do
      assert_required @item, :recaptcha
    end

    test 'email should be validated' do
      assert_email_validation @item, :email
    end

    test 'recaptcha should be validated' do
      assert_recaptcha_validation @item, :recaptcha
    end


  end
end