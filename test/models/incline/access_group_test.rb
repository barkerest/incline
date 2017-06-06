require 'test_helper'

module Incline
  class AccessGroupTest < ActiveSupport::TestCase

    def setup
      @group = Incline::AccessGroup.new(name: 'Group X')
      @group1 = incline_access_groups(:one)
    end

    test 'should be valid' do
      assert @group.valid?
    end

    test 'should require name' do
      assert_required @group, :name
    end

    test 'name should not be too long' do
      assert_max_length @group, :name, 100
    end

    test 'name should be unique' do
      assert_uniqueness @group, :name
    end

    test 'should allow members' do
      # must save before adding.
      @group.save!
      @group.reload

      @group.groups << @group1

      assert @group.valid?

      @group.save!

      # group-x should have one member and group-1 should belong to one group.
      assert_equal 1, @group.groups(true).count
      assert_equal 1, @group1.memberships(true).count

      # group-x has group-1 as a member and group-1 is a member of group-x.
      assert @group.groups.include?(@group1)
      assert @group1.memberships.include?(@group)

      # group-1 equates to both group-1 and group-x for effective groups.
      assert @group1.effective_groups.include?(@group1)
      assert @group1.effective_groups.include?(@group)

      # group-x equates to group-x but not group-1 for effective groups.
      assert @group.effective_groups.include?(@group)
      assert_not @group.effective_groups.include?(@group1)

      # group-1 belongs to group-x but group-x does not belong to group-1.
      assert @group1.belongs_to?(@group)
      assert_not @group.belongs_to?(@group1)
    end

  end
end
