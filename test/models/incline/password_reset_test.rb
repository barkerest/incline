require 'test_helper'

module Incline
  class PasswordResetTest < ActiveSupport::TestCase

    def setup
      @item = Incline::PasswordReset.new(
          password: 'password',
          password_confirmation: 'password',
          recaptcha: Incline::Recaptcha::DISABLED
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require password' do
      assert_required @item, :password
    end

    test 'should require minimum password length' do
      @item.password = @item.password_confirmation = 'a' * 8
      assert @item.valid?

      @item.password = @item.password_confirmation = 'a' * 7
      assert_not @item.valid?
      assert @item.errors[:password].to_s =~ /is too short/
    end

    test 'should require password_confirmation' do
      assert_required @item, :password_confirmation
    end

    test 'password_confirmation should match password' do
      @item.password_confirmation = 'a' * 8
      assert_not @item.valid?
      assert @item.errors[:password_confirmation].to_s =~ /doesn't match/
    end

    test 'should require recaptcha' do
      assert_required @item, :recaptcha
    end

    test 'should validate recaptcha' do
      assert_recaptcha_validation @item, :recaptcha
    end


  end
end