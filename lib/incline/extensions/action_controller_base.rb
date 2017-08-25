require 'action_controller'

module Incline::Extensions

  ##
  # Adds some extra functionality to the base controller definition.
  module ActionControllerBase

    ##
    # Adds some class methods to the base action controller.
    module ClassMethods

      ##
      # Turn on auto API for the controller.
      def enable_auto_api
        @enable_auto_api = true
      end

      ##
      # Turn off auto API for the controller.
      def disable_auto_api
        @enable_auto_api = false
      end

      ##
      # Determines if the controller is configured for auto API.
      def auto_api?
        @enable_auto_api ||= false
      end

      ##
      # Enables or disables HTTP (non-SSL) for actions.
      #
      # Pass +false+ to disable HTTP for all actions(default).
      # Pass +true+ to enable HTTP for all actions.
      # Pass action names to enable HTTP for specific actions.
      #
      # With no arguments, the current setting is returned.
      #
      #     allow_non_ssl false
      #     allow_non_ssl true
      #     allow_non_ssl :home, :about
      #
      def allow_non_ssl(*args)
        if args.blank?
          @allow_non_ssl ||= false
        else
          @allow_non_ssl = setting_value(args)
        end
      end

      ##
      # Enables anonymous access for actions.
      #
      # Pass +false+ to disable anonymous access for all actions(default).
      # Pass +true+ to allow anonymous access for all actions.
      # Pass action names to enable anonymous access for specific actions.
      #
      # With no arguments, the current setting is returned.
      #
      #     allow_anon false
      #     allow_anon true
      #     allow_anon :home, :about
      #
      def allow_anon(*args)
        if args.blank?
          @allow_anon ||= false
        else
          @allow_anon = setting_value(args)
        end
      end

      ##
      # Enables requiring a system administrator for actions.
      #
      # Pass +false+ to allow non-system administrators access for all actions(default).
      # Pass +true+ to require system administrators for all actions.
      # Pass action names to require system administrators for specific actions.
      #
      # With no arguments, the current setting is returned.
      #
      #     require_admin false
      #     require_admin true
      #     require_admin :new, :edit, :create, :update, :destroy
      #
      def require_admin(*args)
        if args.blank?
          @require_admin ||= false
        else
          @require_admin = setting_value(args)
        end
      end

      ##
      # Enables requiring an anonymous user for actions.
      #
      # Pass +false+ to allow logged in users access for all actions(default).
      # Pass +true+ to require anonymous users for all actions.
      # Pass action names to require anonymous for specific actions.
      #
      # With no arguments, the current setting is returned.
      #
      #     require_anon false
      #     require_anon true
      #     require_anon :new, :edit, :create, :update, :destroy
      #
      def require_anon(*args)
        if args.blank?
          @require_anon ||= false
        else
          @require_anon = setting_value(args)
        end
      end

      ##
      # Determines if the current request can be allowed with an anonymous user.
      #
      # Overridden by require_admin_for_request?
      # Implied by require_anon_for_request?
      def allow_anon_for?(action)
        require_anon_for?(action) || setting_for_action(allow_anon, action)
      end

      ##
      # Determines if the current request requires a system administrator.
      #
      # Overrides all other access requirements.
      def require_admin_for?(action)
        setting_for_action require_admin, action
      end

      ##
      # Determines if the current request requires an anonymous user.
      #
      # Overridden by require_admin_for_request?
      # Implies allow_anon_for_request?
      def require_anon_for?(action)
        setting_for_action require_anon, action
      end

      ##
      # Determines if the current request can be allowed via HTTP (non-SSL).
      def allow_http_for?(action)
        setting_for_action allow_non_ssl, action
      end


      private

      def setting_value(args)
        if args.include?(false)
          false
        elsif args.include?(true)
          true
        else
          args.map{|v| v.is_a?(::Symbol) ? v : v.to_s.to_sym }
        end
      end

      def setting_for_action(setting, action)
        return false unless setting
        if setting.is_a?(::Array)
          return false unless setting.include?(action.to_sym)
        end
        true
      end

    end

    ##
    # Enforces SSL and catches Incline::NotLoggedIn exceptions.
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do

        # Force SSL under production environments unless allow_http_for_request returns true.
        if Rails.env.production?
          force_ssl unless: :allow_http_for_request?
        end

        # Process user authorization for all actions except the GET/POST api actions.
        # These get to be authorized once the actual action is selected.
        before_action :valid_user?, except: [ :api ]

        undef process_action

        ##
        # Override the default to enable auto-api behavior if desired.
        def process_action(method_name, *args) #:nodoc:
          if self.class.auto_api?
            unless process_api_action(false, nil)
              super method_name, *args
            end
          else
            super method_name, *args
          end
        end

        rescue_from ::Incline::NotLoggedIn do |exception|
          flash[:info] = exception.message
          store_location
          redirect_to(incline.login_url)
        end

      end
    end

    ##
    # Renders the view as a CSV file.
    #
    # Set the +filename+ you would like to provide to the client, or leave it nil to use the action name.
    # Set the +view_name+ you would like to render, or leave it nil to use the action name.
    def render_csv(filename = nil, view_name = nil)

      filename ||= params[:action]
      view_name ||= params[:action]
      filename.downcase!
      filename += '.csv' unless filename[-4..-1] == '.csv'

      headers['Content-Type'] = 'text/csv'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""

      render view_name, layout: false
    end

    ##
    # A redirects to a previously stored location or to the default location.
    #
    # Usually this will be used to return to an action after a user logs in.
    def redirect_back_or(default)
      redirect_to session[:forwarding_url] || default
      session.delete :forwarding_url
    end

    ##
    # Stores the current URL to be used with #redirect_back_or.
    def store_location
      session[:forwarding_url] = request.url if request.get?
    end




    protected

    ##
    # This method maps the requested action into the actual action performed.
    #
    # By default, the requested action is returned.  If for some reason you want to use a different
    # action in your API, override this method in your controller and map the actions as appropriate.
    #
    # The actions you can expect to translate are 'index', 'new', 'show', and 'edit' for GET requests, and
    # 'create', 'update', and 'destroy' for POST requests.  They will be string values or nil, they will not be
    # symbols.
    #
    # The default behavior causes the API to "fall through" to your standard controller methods.
    #
    # The API is accessed by either a POST or a GET request that specifies an `action` parameter.  The action
    # gets translated to the acceptable actions listed above and then run through this method for translation.
    #
    def map_api_action(requested_action) #:doc:
      requested_action
    end


    ##
    # Authorizes access for the action.
    #
    # * With no arguments, this will validate that a user is currently logged in, but does not check their permission.
    # * With an argument of true, this will validate that the user currently logged in is an administrator.
    # * With one or more strings, this will validate that the user currently logged in has at least one or more
    #   of the named permissions.
    #
    #     authorize!
    #     authorize! true
    #     authorize! "Safety Manager", "HR Manager"
    #
    # If no user is logged in, then the user will be redirected to the login page and the method will return false.
    # If a user is logged in, but is not authorized, then the user will be redirected to the home page and the method
    # will return false.
    # If the user is authorized, the method will return true.
    def authorize!(*accepted_groups) #:doc:
      begin

        # an authenticated user must exist.
        unless logged_in?
          
          if (auth_url = ::Incline::UserManager.begin_external_authentication(request))
            ::Incline::Log.debug 'Redirecting for external authentication.'
            redirect_to auth_url
            return false
          end
          
          store_location

          raise_not_logged_in "You need to login to access '#{request.fullpath}'.",
                              'nobody is logged in'
        end

        if system_admin?
          log_authorize_success 'user is system admin'
        else
          # clean up the group list.
          accepted_groups ||= []
          accepted_groups.flatten!
          accepted_groups.delete false
          accepted_groups.delete ''

          if accepted_groups.include?(true)
            # group_list contains "true" so only a system admin may continue.
            raise_authorize_failure "Your are not authorized to access '#{request.fullpath}'.",
                                      'requires system administrator'

          elsif accepted_groups.blank?
            # group_list is empty or contained nothing but empty strings and boolean false.
            # everyone can continue.
            log_authorize_success 'only requires authenticated user'

          else
            # the group list contains one or more authorized groups.
            # we want them to all be uppercase strings.
            accepted_groups = accepted_groups.map{|v| v.to_s.upcase}.sort
            result = current_user.has_any_group?(*accepted_groups)
            unless result
              raise_authorize_failure "You are not authorized to access '#{request.fullpath}'.",
                                      "requires one of: #{accepted_groups.inspect}"
            end
            log_authorize_success "user has #{result.inspect}"
          end
        end

      rescue ::Incline::NotAuthorized => err
        flash[:danger] = err.message
        redirect_to main_app.root_url
        return false
      end
      true

    end

    ##
    # Is the current request for JSON data?
    #
    # Redirects are generally bad when JSON data is requested.
    # For instance a `create` request in JSON format should return data, not redirect to `show`.
    def json_request? #:doc:
      request.format.to_s.downcase == 'json'
    end

    ##
    # Is the current request an inline request?
    #
    # JSON requests are always considered inline, otherwise we check to see if the "inline" parameter is set to a true value.
    #
    # Primarily this would be used to strip the layour from rendered content.
    def inline_request?
      json_request? || params[:inline].to_bool
    end

    ##
    # Determines if the current request can be allowed via HTTP (non-SSL).
    def allow_http_for_request? #:doc:
      self.class.allow_http_for? params[:action]
    end

    ##
    # Determines if the current request can be allowed with an anonymous user.
    #
    # Overridden by require_admin_for_request?
    # Implied by require_anon_for_request?
    def allow_anon_for_request? #:doc:
      self.class.allow_anon_for? params[:action]
    end

    ##
    # Determines if the current request requires a system administrator.
    #
    # Overrides all other access requirements.
    def require_admin_for_request? #:doc:
      self.class.require_admin_for? params[:action]
    end

    ##
    # Determines if the current request requires an anonymous user.
    #
    # Overridden by require_admin_for_request?
    # Implies allow_anon_for_request?
    def require_anon_for_request? #:doc:
      self.class.require_anon_for? params[:action]
    end


    private

    ##
    # Validates that the current user is authorized for the current request.
    #
    # This method is called for every action except the :api action.
    # For the :api action, this method will not be called until the actual requested action is performed.
    #
    # One of four scenarios are possible:
    # 1.  If the +require_admin+ method applies to the current action, then a system administrator must be logged in.
    #     1.  If a nobody is logged in, then the user will be redirected to the login url.
    #     2.  If a system administrator is logged in, then access is granted.
    #     3.  Non-system administrators will be redirected to the root url.
    # 2.  If the +require_anon+ method applies to the current action, then a user cannot be logged in.
    #     1.  If a user is logged in, a warning message is set and the user is redirected to their account.
    #     2.  If no user is logged in, then access is granted.
    # 3.  If the +allow_anon+ method applies to the current action, then access is granted.
    # 4.  The action doesn't require a system administrator, but does require a valid user to be logged in.
    #     1.  If nobody is logged in, then the user will be redirected to the login url.
    #     2.  If a system administrator is logged in, then access is granted.
    #     3.  If the action doesn't have any required permissions, then access is granted to any logged in user.
    #     4.  If the action has required permissions and the logged in user shares at least one, then access is granted.
    #     5.  Users without at least one required permission are redirected to the root url.
    #
    # Two of the scenarios are configured at design time. If you use +require_admin+ or +allow_anon+,
    # they cannot be changed at runtime.  The idea is that anything that allows anonymous access will always allow
    # anonymous access during runtime and anything that requires admin access will always require admin access during
    # runtime.
    #
    # The third scenario is what would be used by most actions.  Using the +admin+ controller, which requires admin
    # access, you can customize the permissions required for each available route.  Using the +users+ controller,
    # admins can assign permissions to other users.
    #
    def valid_user? #:doc:
      if require_admin_for_request?
        authorize! true
      elsif require_anon_for_request?
        if logged_in?
          flash[:warning] = 'The specified action cannot be performed while logged in.'
          redirect_to current_user
        end
      elsif allow_anon_for_request?
        true
      else
        action = Incline::ActionSecurity.valid_items[self.class.controller_path, params[:action]]
        if action && action.groups.count > 0
          authorize! action.groups.pluck(:name)
        else
          authorize!
        end
      end
    end


    def process_api_action(raise_on_invalid_action = true, default_get_action = 'index')
      api_action =
          map_api_action(
              if request.post?
                # A post request can create, update, or destroy.
                # In addition we allow index to post since DataTables can send quite a bit of data with server-side
                # processing.
                # The post action can be provided as a query parameter or a form parameter with the form parameter
                # taking priority.
                {
                    nil => 'index',
                    'list' => 'index',
                    'index' => 'index',
                    'new' => 'create',
                    'create' => 'create',
                    'edit' => 'update',
                    'update' => 'update',
                    'remove' => 'destroy',
                    'destroy' => 'destroy'
                }[request.request_parameters.delete('action') || request.query_parameters.delete('action')]
              elsif request.get?
                # For the most part, these shouldn't be used except for maybe index and show.
                # The new and edit actions could be used if for some reason you need to supply data to the ajax form
                # calling these actions, e.g. - a list of locations.
                # Datatables Editor does not use any of them.
                # Datatables will simple be requesting the index action in JSON format.
                # To remain consistent though, you can use '?action=list' to perform the same feat.
                {
                    'list' => 'index',
                    'index' => 'index',
                    'new' => 'new',
                    'show' => 'show',
                    'edit' => 'edit'
                }[request.query_parameters.delete('action')] || default_get_action
              else
                nil
              end
          )

      if api_action
        # Datatables Editor sends the 'data' in the 'data' parameter.
        # We simple want to move that up a level so `params[:data][:user][:name]` becomes `params[:user][:name]`.
        data = request.params.delete('data')
        unless data.blank?
          # get the first entry in the hash.
          id, item = data.first

          # if the id is in AAAAA_NNN format, then we can extract the ID from it.
          if id.include?('_')
            params[:id] = id.split('_').last.to_i
          end

          # merge the item data into the params array.
          params.merge! item
        end

        # since we are processing for an API request, we should return JSON.
        request.format = :json

        # finally, we'll start over on processing the stack.
        # This should ensure the appropriate `before_action` filters are called for the new action.
        process api_action
      else
        # raise an error.
        raise Incline::InvalidApiCall, 'Invalid API Action' if raise_on_invalid_action
        nil
      end
    end

    def raise_authorize_failure(message, log_message = nil)
      log_authorize_failure message, log_message
      raise Incline::NotAuthorized.new(message)
    end

    def raise_not_logged_in(message, log_message = nil)
      log_authorize_failure message, log_message
      raise Incline::NotLoggedIn.new(message)
    end

    def log_authorize_failure(message, log_message = nil)
      log_message ||= message
      Incline::Log::info "AUTH(FAILURE): #{request.fullpath}, #{current_user}, #{log_message}"
    end

    def log_authorize_success(message)
      Incline::Log::info "AUTH(SUCCESS): #{request.fullpath}, #{current_user}, #{message}"
    end

  end

end

ActionController::Base.include Incline::Extensions::ActionControllerBase

