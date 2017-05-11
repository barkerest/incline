require 'test_helper'

module Incline
  class UsersControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should get new" do
      get signup_path
      assert_response :success
    end

  end
end
