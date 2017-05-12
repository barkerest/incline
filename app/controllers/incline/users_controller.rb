require_dependency "incline/application_controller"

module Incline
  class UsersController < ApplicationController

    def index

    end

    ##
    # GET /incline/signup
    def new
      @user = Incline::User.new
    end

    def create

    end

    def show

    end

    def edit

    end

    def destroy

    end

    private



  end
end
