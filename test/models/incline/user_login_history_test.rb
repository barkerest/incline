require 'test_helper'

module Incline
  class UserLoginHistoryTest < ActiveSupport::TestCase
    def setup
      @user = incline_users(:one)
      @item = Incline::UserLoginHistory.new(user: @user, ip_address: '1.2.3.4')
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require user' do
      assert_required @item, :user
    end

    test 'should require ip_address' do
      assert_required @item, :ip_address
    end

    test 'should validate ip_address' do
      assert_ip_validation @item, :ip_address, :deny_mask
    end

    test 'message should not be too long' do
      assert_max_length @item, :message, 200
    end

  end
end
