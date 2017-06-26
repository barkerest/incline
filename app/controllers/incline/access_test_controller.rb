module Incline
  class AccessTestController < ActionController::Base

    require_anon :test_require_anon
    allow_anon :test_allow_anon
    require_admin :test_require_admin

    def test_require_anon
      render text: 'OK'
    end

    def test_allow_anon
      render text: 'OK'
    end

    def test_require_admin
      render text: 'OK'
    end

    def test_require_user
      render text: 'OK'
    end

    # Fixtures should define 'Group 1' as being a group for this action.
    def test_require_group
      render text: 'OK'
    end

  end
end