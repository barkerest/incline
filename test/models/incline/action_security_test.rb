require 'test_helper'

module Incline
  class ActionSecurityTest < ActiveSupport::TestCase

    class EveryoneController < ActionController::Base
      allow_anon true
    end

    class AnonOnlyController < ActionController::Base
      require_anon true
    end

    class AdminOnlyController < ActionController::Base
      require_admin true
    end

    class AnyUserController < ActionController::Base

    end

    class MixedController < ActionController::Base
      allow_anon :index
      require_anon :new, :create
      require_admin :edit, :update, :destroy
      # And the final CRUD action (:show) is currently allowed by any logged in user.
    end

    def setup
      @item = Incline::ActionSecurity.new(path: '/things', controller_name: 'things', action_name: 'index')
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require path' do
      assert_required @item, :path
    end

    test 'should require controller_name' do
      assert_required @item, :controller_name
    end

    test 'should require action_name' do
      assert_required @item, :action_name
    end

    test 'should limit length of controller_name' do
      assert_max_length @item, :controller_name, 200
    end

    test 'should limit length of action_name' do
      assert_max_length @item, :action_name, 200
    end

    test 'action_name should be unique within controller_name' do
      assert_uniqueness @item, :action_name, controller_name: 'other_things'
    end

    test 'names are stored in lowercase' do
      @item.controller_name = 'THINGS'
      assert_equal 'THINGS', @item.controller_name
      @item.save!
      assert_equal 'things', @item.controller_name
      @item.action_name = 'SHOW'
      assert_equal 'SHOW', @item.action_name
      @item.save!
      assert_equal 'show', @item.action_name
    end

    test 'allow_custom? works correctly' do
      assert @item.allow_custom?
      @item.require_admin = true
      assert_not @item.allow_custom?
      @item.require_admin = false
      @item.require_anon = true
      assert_not @item.allow_custom?
      @item.require_anon = false
      @item.allow_anon = true
      assert_not @item.allow_custom?
      @item.allow_anon = false
      assert @item.allow_custom?
    end

    test 'short_permitted works correctly' do

      {
          nil => 'Users',
          require_admin: 'Admins',
          require_anon: 'Anon',
          allow_anon: 'Everyone'
      }.each do |attr,ret|
        @item.send("#{attr}=", true) if attr
        assert_equal ret, @item.short_permitted
        @item.non_standard = true
        assert_equal ret + '*', @item.short_permitted
        @item.non_standard = false
        @item.send("#{attr}=", false) if attr
      end
      assert_equal 'Users', @item.short_permitted

      @item.groups << incline_access_groups(:one)
      assert_equal 'Custom', @item.short_permitted
    end

    test 'anon_only test' do
      %w(index new create show edit update destroy).each do |action|
        @item = Incline::ActionSecurity.new(path: '/', controller_name: 'incline/action_security_test/anon_only', action_name: action)
        @item.update_flags
        assert_not @item.unknown_controller?
        assert @item.require_anon?
        assert_not @item.allow_anon?
        assert_not @item.require_admin?
        assert_not @item.allow_custom?
      end
    end

    test 'everyone test' do
      %w(index new create show edit update destroy).each do |action|
        @item = Incline::ActionSecurity.new(path: '/', controller_name: 'incline/action_security_test/everyone', action_name: action)
        @item.update_flags
        assert_not @item.unknown_controller?
        assert_not @item.require_anon?
        assert @item.allow_anon?
        assert_not @item.require_admin?
        assert_not @item.allow_custom?
      end
    end

    test 'admin_only test' do
      %w(index new create show edit update destroy).each do |action|
        @item = Incline::ActionSecurity.new(path: '/', controller_name: 'incline/action_security_test/admin_only', action_name: action)
        @item.update_flags
        assert_not @item.unknown_controller?
        assert_not @item.require_anon?
        assert_not @item.allow_anon?
        assert @item.require_admin?
        assert_not @item.allow_custom?
      end
    end

    test 'any_user test' do
      %w(index new create show edit update destroy).each do |action|
        @item = Incline::ActionSecurity.new(path: '/', controller_name: 'incline/action_security_test/any_user', action_name: action)
        @item.update_flags
        assert_not @item.unknown_controller?
        assert_not @item.require_anon?
        assert_not @item.allow_anon?
        assert_not @item.require_admin?
        assert @item.allow_custom?
      end
    end

    test 'mixed test' do
      {   #           anon    allow   admin   user
          index:    [ false,  true,   false,  false ],
          new:      [ true,   false,  false,  false ],
          create:   [ true,   false,  false,  false ],
          show:     [ false,  false,  false,  true ],
          edit:     [ false,  false,  true,   false ],
          update:   [ false,  false,  true,   false ],
          destroy:  [ false,  false,  true,   false ]
      }.each do |action,(anon,allow,admin,user)|
        @item = Incline::ActionSecurity.new(path: '/', controller_name: 'incline/action_security_test/mixed', action_name: action)
        @item.update_flags
        assert_not @item.unknown_controller?
        assert_equal anon,  @item.require_anon?
        assert_equal allow, @item.allow_anon?
        assert_equal admin, @item.require_admin?
        assert_equal user,  @item.allow_custom?
      end
    end

  end
end
