require 'test_helper'

module Incline
  class AccessGroupGroupMemberTest < ActiveSupport::TestCase
    def setup
      @group1 = incline_access_groups(:one)
      @group2 = incline_access_groups(:two)
      @group3 = incline_access_groups(:three)
      @item = Incline::AccessGroupGroupMember.new(group_id: @group1.id, member_id: @group2.id)
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
      assert_uniqueness @item, :member_id, false, group_id: @group3.id
    end


  end
end
