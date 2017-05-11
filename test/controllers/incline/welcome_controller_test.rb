require 'test_helper'

module Incline
  class WelcomeControllerTest < ActionController::TestCase
    setup do
      @routes = Engine.routes
    end

    test "should get home" do
      get root_path
      assert_response :success
    end

  end
end
