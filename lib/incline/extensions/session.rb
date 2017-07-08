require 'action_view'
require 'action_controller'
require 'action_mailer'
require 'action_dispatch'

module Incline::Extensions

  ##
  # Patches the views and controllers to have access to user session features.
  module Session

    ##
    # Contains the methods common to both controllers and views.
    module Common

      ##
      # Gets the name of the cookie containing the user ID for the current user.
      #
      # This gets set when the user selects the "Remember me" checkbox when logging in.
      def user_id_cookie
        @user_id_cookie ||= Rails.application.cookie_name(:user_id)
      end

      ##
      # Gets the name of the cookie containing the remember token for the current user.
      #
      # This gets set when the user selects the "Remember me" checkbox when logging in.
      def user_token_cookie
        @user_token_cookie ||= Rails.application.cookie_name(:user_token)
      end

      ##
      # Gets the currently logged in user.
      def current_user
        @current_user ||=
            if (user_id = session[:user_id])
              Incline::User.find_by(id: user_id)
            elsif (cookies&.respond_to?(:signed)) &&
                (user_id = cookies.signed[user_id_cookie]) &&
                (user = Incline::User.find_by(id: user_id)) &&
                (user.authenticated?(:remember, cookies[user_token_cookie]))
              log_in user if respond_to?(:log_in)
              user
            else
              nil
            end ||Incline::User::anonymous
      end

      ##
      # Is the specified user the current user?
      def current_user?(user)
        current_user == user
      end

      ##
      # Is a user logged in?
      def logged_in?
        !current_user.anonymous?
      end

      ##
      # Is the current user a system administrator?
      def system_admin?
        logged_in? && current_user.system_admin? && current_user.enabled? && current_user.activated?
      end

    end

    ##
    # Contains the methods specific to controllers.
    module Controller

      ##
      # Logs in the given user.
      def log_in(user)
        session[:user_id] = user.id
      end

      ##
      # Logs out any currently logged in user.
      def log_out
        forget current_user
        session.delete(:user_id)
        @current_user = nil
      end

      ##
      # Stores the user ID to the permanent cookie store to keep the user logged in.
      def remember(user)
        user.remember
        cookies.permanent.signed[user_id_cookie] = user.id
        cookies.permanent[user_token_cookie] = user.remember_token
      end

      ##
      # Removes the user from the permanent cookie store.
      def forget(user)
        user.forget
        cookies.delete(user_id_cookie)
        cookies.delete(user_token_cookie)
      end

    end

  end
end

ActionView::Base.include Incline::Extensions::Session::Common
ActionMailer::Base.include Incline::Extensions::Session::Common
ActionController::Base.include Incline::Extensions::Session::Common
ActionController::Base.include Incline::Extensions::Session::Controller
ActionDispatch::IntegrationTest.include Incline::Extensions::Session::Common

