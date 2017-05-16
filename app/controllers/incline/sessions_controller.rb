module Incline
  ##
  # A simple controller providing the login and logout methods for the application.
  class SessionsController < ApplicationController

    require_anon :new, :create
    allow_anon true

    ##
    # GET /incline/login
    def new
    end

    ##
    # POST /incline/login
    def create
      if (@user = Incline::UserManager.authenticate(params[:session][:email], params[:session][:password], request.remote_ip))
        if @user.activated?
          # log the user in.
          log_in @user
          params[:session][:remember_me] == '1' ? remember(@user) : forget(@user)

          # show alerts on login.
          session[:show_alerts] = true

          redirect_back_or @user
        else
          flash[:safe_warning] = 'Your account has not yet been activated.<br/>Check your email for the activation link.'
          redirect_to root_url
        end
      else
        # deny login.
        flash.now[:danger] = 'Invalid email or password.'
        render 'new'
      end
    end

    ##
    # DELETE /incline/logout
    def destroy
      log_out if logged_in?
      redirect_to root_url
    end

  end

end