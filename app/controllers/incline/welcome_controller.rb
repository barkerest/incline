require_dependency "incline/application_controller"

module Incline
  ##
  # An innocuous controller that simply hosts the home page of the application.
  class WelcomeController < ApplicationController
    ##
    # Get /incline
    #
    # Use +root "incline/welcome#home"+ in your +routes.rb+ file to use this, or define your own
    # home page as desired.
    def home

    end
  end
end
