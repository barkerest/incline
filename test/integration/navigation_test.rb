  require 'test_helper'

  class NavigationTest < ActionDispatch::IntegrationTest

    test 'layout links' do
      get root_path
      assert_select 'a[href=?]', root_path, count: 2
      # TODO: Test more links.
    end

  end