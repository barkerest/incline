require 'test_helper'

module Incline
  class AccessGroupUserMemberTest < ActiveSupport::TestCase
    def setup
      @group1 = incline_access_groups(:one)
      @group2 = incline_access_groups(:two)
      @user = incline_users(:one)
      @item = Incline::AccessGroupUserMember.new(group_id: @group1.id, member_id: @user.id)
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require group_id' do
      assert_required @item, :group_id
    end

    test 'should require member_id' do
      assert_required @item, :member_id
    end

    test 'member_id should be unique within group_id scope' do
      assert_uniqueness @item, :member_id, false, group_id: @group2.id
    end

  end
end
