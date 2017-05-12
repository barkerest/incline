require_dependency "incline/application_controller"

module Incline
  class UsersController < ApplicationController
    def new
      @user = Incline::User.new
    end

  end
end
