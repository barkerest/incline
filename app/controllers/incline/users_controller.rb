# require_dependency "incline/application_controller"

module Incline
  class UsersController < ApplicationController

    before_action :set_user,          except: [ :index, :new, :create, :api ]
    before_action :set_disable_info,  only: [ :disable_confirm, :disable ]
    before_action :not_current,       only: [ :destroy, :disable, :disable_confirm, :enable, :promote, :demote ]

    layout :use_layout, except: [ :index ]

    # Only anonymous users can signup.
    require_anon :new, :create

    # Only admins can delete/disable/enable users, or list all users, or show/edit/update other users.
    require_admin :index, :show, :edit, :update, :destroy, :disable, :disable_confirm, :enable, :promote, :demote

    ##
    # GET /incline/users
    def index
      @dt_request = Incline::DataTablesRequest.new(params) do
        (current_user.system_admin? ? Incline::User.known : Incline::User.known.enabled)
      end
    end

    ##
    # GET /incline/signup
    def new
      @user = Incline::User.new
    end

    ##
    # POST /incline/signup
    def create
      @user = Incline::User.new(user_params :before_create)
      if @user.valid?
        if @user.save
          @user.send_activation_email request.remote_ip
          if system_admin?
            flash[:info] = "The user #{@user} has been created, but the user will need to activate their account before use."
            additional_params = user_params :after_create
            if additional_params.any?
              unless @user.update_attributes(additional_params)
                flash[:warning] = 'Failed to apply additional attributes to new user account.'
              end
            end
            redirect_to users_url and return
          else
            flash[:safe_info] = 'Your account has been created, but needs to be activated before you can use it.<br>Please check your email to activate your account.'
            redirect_to root_url and return
          end
        else
          @user.errors[:base] << 'Failed to create user account.'
        end
      end
      render 'new'
    end

    ##
    # GET /incline/users/1
    def show
      render 'show'
    end

    ##
    # GET /incline/users/1/edit
    def edit
      render 'edit'
    end

    ##
    # PUT /incline/users/1
    def update
      if @user.update_attributes(user_params)
        if current_user?(@user)
          flash[:success] = 'Your profile has been updated.'
          redirect_to @user
        else
          flash[:success] = "The user #{@user} has been updated."
          redirect_to users_path
        end
      else
        render 'edit'
      end
    end

    ##
    # DELETE /incline/users/1
    def destroy
      if @user.enabled?
        flash[:danger] = 'Cannot delete an enabled user.'
      elsif @user.disabled_at.blank? || @user.disabled_at > 15.days.ago
        flash[:danger] = 'Cannot delete a user within 15 days of being disabled.'
      else
        @user.destroy
        flash[:success] = "User #{@user} has been deleted."
      end
      redirect_to users_path
    end

    ##
    # GET /incline/users/1/disable
    def disable_confirm
      unless @disable_info.user.enabled?
        flash[:warning] = "User #{@disable_info.user} is already disabled."
        redirect_to users_path
      end
    end

    ##
    # PUT /incline/users/1/disable
    def disable
      if @disable_info.valid?
        if @disable_info.user.disable(current_user, @disable_info.reason)
          flash[:success] = "User #{@disable_info.user} has been disabled."
          redirect_to users_path and return
        else
          @disable_info.errors.add(:user, 'was unable to be updated')
        end
      end

      render 'disable_confirm'
    end

    ##
    # PUT /incline/users/1/enable
    def enable
      if @user.enabled?
        flash[:warning] = "User #{@user} is already enabled."
        redirect_to users_path and return
      end

      if @user.enable
        flash[:success] = "User #{@user} has been enabled."
      else
        flash[:danger] = "Failed to enable user #{@user}."
      end

      redirect_to users_path
    end

    ##
    # PUT /incline/users/1/promote
    def promote
      # add the administrator flag to the selected user.
      if @user.system_admin?
        flash[:warning] = "User #{@user} is already an administrator."
        redirect_to users_path and return
      end

      if @user.update(system_admin: true)
        flash[:success] = "User #{@user} has been promoted to administrator."
      else
        flash[:danger] = "Failed to promote user #{@user}."
      end

      redirect_to users_path
    end

    ##
    # PUT /incline/users/1/demote
    def demote
      # remove the administrator flag from the selected user.
      unless @user.system_admin?
        flash[:warning] = "User #{@user} is not an administrator."
        redirect_to users_path and return
      end

      if @user.update(system_admin: false)
        flash[:success] = "User #{@user} has been demoted from administrator."
      else
        flash[:danger] = "Failed to demote user #{@user}."
      end

      redirect_to users_path
    end


    # GET/POST /incline/users/api?action=...
    def api
      process_api_action
    end

    private

    # if the "inline" parameter evaluates to true then don't use a layout, otherwise use the inherited layout.
    def use_layout
      params[:inline].to_bool ? false : nil
    end

    def valid_user?
      # This method allows us to override the "require_admin" and "require_anon" settings for these actions.

      action = params[:action].to_sym

      # The current user can show or edit their own details without any further validation.
      return true if [ :show, :edit, :update ].include?(action) && logged_in? && current_user?(set_user)

      # A system administrator can create new users.
      return true if [ :new, :create ].include?(action) && logged_in? && system_admin?

      super
    end

    def set_user
      @user ||=
          if system_admin?
            Incline::User.find(params[:id])
          else
            Incline::User.enabled.find(params[:id])
          end ||
              Incline::User.new(name: 'Invalid User', email: 'invalid-user')
    end

    def set_disable_info
      @disable_info = Incline::DisableInfo.new(disable_info_params)
      @disable_info.user = @user
    end

    def user_params(mode = :all)
      ok = (mode == :all || mode == :before_create) ? [ :name, :email, :password, :password_confirmation, :recaptcha ] : [ ]

      # admins can add groups to other users.
      ok += [ { group_ids: [] } ] if (mode == :all || mode == :after_create) && logged_in? && system_admin? && !current_user?(set_user)

      params.require(:user).permit(ok)
    end

    def disable_info_params
      params[:disable_info] ?
          params.require(:disable_info).permit(:reason) :
          { }
    end

    def not_current
      if current_user?(@user)
        flash[:warning] = 'You cannot perform this operation on yourself.'
        redirect_to users_path
      end
    end

  end
end
