require 'test_helper'

module Incline
  class DisableInfoTest < ActiveSupport::TestCase

    def setup
      @item = Incline::DisableInfo.new(user: incline_users(:one), reason: 'For testing')
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require user' do
      assert_required @item, :user, nil, /must be provided/
    end

    test 'should require reason' do
      assert_required @item, :reason
    end

    test 'user must be enabled' do
      @item.user = incline_users(:disabled)
      assert_not @item.valid?
      assert @item.errors[:user].to_s =~ /must be enabled/
    end

  end
end