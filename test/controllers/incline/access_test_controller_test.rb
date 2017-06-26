require 'test_helper'

module Incline

  class AccessTestControllerTest < ::ActionDispatch::IntegrationTest

    def setup
      # basic user and admin user.
      @user = incline_users(:basic)
      @admin = incline_users(:admin)

      # group member.
      group = incline_access_groups(:one)
      @member = incline_users(:one)
      @member.groups = [ group ]

    end

    access_tests_for :allow_anon,
                     allow_anon: true,
                     allow_any_user: true,
                     allow_admin: true,
                     url_helper: 'incline.test_allow_anon_path'

    access_tests_for :require_anon,
                     allow_anon: true,
                     allow_any_user: false,
                     allow_admin: false,
                     url_helper: 'incline.test_require_anon_path',
                     failure: 'incline.user_path(user)'

    access_tests_for :require_admin,
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     url_helper: 'incline.test_require_admin_path'

    access_tests_for :require_user,
                     allow_anon: false,
                     allow_any_user: true,
                     allow_admin: true,
                     url_helper: 'incline.test_require_user_path'

    access_tests_for :require_group,
                     allow_anon: false,
                     allow_any_user: false,
                     allow_admin: true,
                     allow_groups: [ 'Group 1' ],
                     url_helper: 'incline.test_require_group_path'

  end

end