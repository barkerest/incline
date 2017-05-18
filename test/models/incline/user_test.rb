require 'test_helper'

module Incline
  class UserTest < ActiveSupport::TestCase
    def setup
      @item = Incline::User.new(
          name: 'John Wayne',
          email: 'j.wayne@example.com',
          password: 'password',
          password_confirmation: 'password',
          recaptcha: Incline::Recaptcha::DISABLED
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require name' do
      assert_required @item, :name
    end

    test 'should require email' do
      assert_required @item, :email
    end

    test 'should require recaptcha' do
      assert_required @item, :recaptcha
    end

    test 'recaptcha not required for updates' do
      @item.save!
      @item.recaptcha = nil
      assert @item.valid?
    end

    test 'name should not be too long' do
      assert_max_length @item, :name, 100
    end

    test 'email should not be too long' do
      assert_max_length @item, :email, 250, end_with: '@example.com'
    end

    test 'email should be unique' do
      assert_uniqueness @item, :email
    end

    test 'email should be saved lowercase' do
      mixed_case_email = 'JohnDoe@Example.COM'
      @item.email = mixed_case_email
      assert @item.valid?
      assert_equal mixed_case_email, @item.email
      @item.save!
      assert_equal mixed_case_email.downcase, @item.email
    end

    test 'password should have min length' do
      pwd = 'a' * 8
      @item.password = @item.password_confirmation = pwd
      assert @item.valid?
      pwd = 'a' * 7
      @item.password = @item.password_confirmation = pwd
      assert_not @item.valid?
    end

    test 'password should not be blank' do
      @item.password = @item.password_confirmation = ' ' * 8
      assert_not @item.valid?
    end

    test 'password_confirmation must match' do
      @item.password_confirmation = 'a' * 8
      assert_not @item.valid?
    end

    test 'authenticated should return false for nil digest' do
      assert_not @item.authenticated?(:remember, '')
    end


  end
end
