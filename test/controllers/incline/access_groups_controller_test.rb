require 'test_helper'

module Incline
  class AccessGroupsControllerTest < ::ActionDispatch::IntegrationTest

    def setup
      @user_ids = [ incline_users(:one).id, incline_users(:two).id ]
      @group_ids = [ incline_access_groups(:three).id, incline_access_groups(:four).id ]
    end

    PARAM_STRING = "{ :access_group => { :name => 'Another Group', :user_ids => @user_ids, :group_ids => @group_ids }}"

    access_tests_for :index,
                     url_helper: 'incline.access_groups_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :new,
                     url_helper: 'incline.new_access_group_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :create,
                     method: :post,
                     url_helper: 'incline.access_groups_path',
                     success: 'incline.access_groups_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     create_params: PARAM_STRING

    access_tests_for :show,
                     url_helper: 'incline.access_group_path(incline_access_groups(:one))',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :edit,
                     url_helper: 'incline.edit_access_group_path(incline_access_groups(:one))',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :update,
                     method: :patch,
                     url_helper: 'incline.access_group_path(incline_access_groups(:one))',
                     success: 'incline.access_groups_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     update_params: PARAM_STRING

    access_tests_for :destroy,
                     method: :delete,
                     url_helper: 'incline.access_group_path(incline_access_groups(:one))',
                     success: 'incline.access_groups_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true


  end
end