require 'test_helper'

module Incline
  class SecurityControllerTest < ::ActionDispatch::IntegrationTest

    def setup
      @group_ids = [ incline_access_groups(:one).id, incline_access_groups(:two).id ]
    end

    PARAM_STRING = '{ :action_security => { :group_ids => @group_ids }}'

    access_tests_for :index,
                     url_helper: 'incline.index_security_path',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :show,
                     url_helper: 'incline.security_path(incline_action_securities(:one))',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :edit,
                     url_helper: 'incline.edit_security_path(incline_action_securities(:one))',
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true

    access_tests_for :update,
                     url_helper: 'incline.security_path(incline_action_securities(:one))',
                     success: 'incline.index_security_path',
                     method: :patch,
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     update_params: PARAM_STRING
  end
end