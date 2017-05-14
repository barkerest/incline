module Incline
  class AccountActivationsController < ApplicationController

    require_anon true

    ##
    # GET /incline/activate/activation-token?email=user@example.com
    def edit
      if logged_in?
        flash[:danger] = 'You cannot reactivate your account.'
        redirect_to root_url
      else
        user = User.find_by(email: params[:email].downcase)
        if user && !user.activated? && user.authenticated?(:activation, params[:id])
          user.activate
          log_in user
          flash[:success] = 'Your account has been activated.'
          redirect_to user
        else
          flash[:danger] = 'Invalid activation link'
          redirect_to root_url
        end
      end
    end

  end

end