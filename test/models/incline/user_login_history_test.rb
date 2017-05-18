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

    test 'ip_address should be valid IP addresses' do
      [
          '0.0.0.0',
          '1.2.3.4',
          '10.20.30.40',
          '255.255.255.255',
          '10:20::30:40',
          '::1',
          '1:2:3:4:5:6:7:8',
          'A:B:C:D:E:F::'
      ].each do |addr|
        @item.ip_address = addr
        assert @item.valid?, "Should have accepted #{addr.inspect}."
      end
    end

    test 'ip_address should reject invalid IP addresses' do
      [
          'hello',
          '100.200.300.400',
          '10.20.30.40/24',   # should not accept a mask.
          '12345::abcde',
          '1.2.3.4.5'
      ].each do |addr|
        @item.ip_address = addr
        assert_not @item.valid?, "Should have rejected #{addr.inspect}."
      end
    end

    test 'message should not be too long' do
      assert_max_length @item, :message, 200
    end

  end
end
