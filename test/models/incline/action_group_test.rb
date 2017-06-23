require 'test_helper'

module Incline
  class ActionGroupTest < ActiveSupport::TestCase
    def setup
      @item = Incline::ActionGroup.new(action_security: incline_action_securities(:one), access_group: incline_access_groups(:one))
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require action_security' do
      assert_required @item, :action_security
    end

    test 'should require access_group' do
      assert_required @item, :access_group
    end

    test 'access_group should be unique within action_security' do
      assert_uniqueness @item, :access_group, action_security: incline_action_securities(:two)
    end

  end
end
