module Incline
  class PasswordResetsController < ApplicationController
    before_action :set_reset_request, only: [ :new, :create ]
    before_action :set_user, only: [:edit, :update]
    before_action :valid_user, only: [ :edit, :update ]
    before_action :set_reset, only: [ :edit, :update ]
    before_action :check_expiration, only: [ :edit, :update ]

    # The user should NOT be logged in.
    require_anon true


    ##
    # GET /incline/password_resets/new
    def new

    end

    ##
    # POST /incline/password_resets
    def create
      unless @reset_request.valid?
        render 'new' and return
      end

      @user = User.find_by(email: @reset_request.email)
      if @user && @user.enabled? && @user.activated?
        @user.create_reset_digest
        @user.send_password_reset_email request.remote_ip
      elsif @user
        if !@user.enabled?
          User.send_disabled_reset_email(email, request.remote_ip)
        elsif !@user.active?
          User.send_inactive_reset_email(email, request.remote_ip)
        else
          User.send_missing_reset_email(email, request.remote_ip)
        end
      else
        User.send_missing_reset_email(email, request.remote_ip)
      end

      flash[:info] = 'An email with password reset information has been sent to you.'
      redirect_to root_url
    end

    ##
    # GET /incline/password_resets/reset-token?email=user@example.com
    def edit

    end

    ##
    # POST /incline/password_resets/reset-token
    def update
      unless @reset.valid?
        render 'edit' and return
      end

      if @user.update_attributes(password: @reset.password, password_confirmation: @reset.password)
        log_in @user
        flash[:success] = 'Password has been reset.'
        redirect_to @user
      else
        @user.errors[:base] << 'Failed to reset password.'
        render 'edit'
      end
    end

    private

    def set_reset_request
      @reset_request = Incline::PasswordResetRequest.new(reset_request_params)
    end

    def set_reset
      @reset = Incline::PasswordReset.new(reset_params)
    end

    def set_user
      @user = User.find_by(email: params[:email])
    end

    def reset_request_params
      if params[:password_reset_request]
        params.require(:password_reset_request).permit(:email, :recaptcha)
      else
        {}
      end
    end

    def reset_params
      if params[:password_reset]
        merge(params.require(:password_reset).permit(:password, :password_confirmation, :recaptcha))
      else
        {}
      end
    end

    def valid_user
      unless @user && @user.enabled? && @user.activated? && @user.authenticated?(:reset, params[:id])
        redirect_to root_url
      end
    end

    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = 'Password reset request has expired.'
        redirect_to new_password_reset_url
      end
    end

  end
end
