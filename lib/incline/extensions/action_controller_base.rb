module Incline::Extensions

  ##
  # Adds some extra functionality to the base controller definition.
  module ActionControllerBase

    ##
    # Enforces SSL and catches Incline::NotLoggedIn exceptions.
    def self.included(base)
      base.class_eval do

        # Force SSL under production environments unless allow_http_for_request returns true.
        if Rails.env.production?
          force_ssl unless: :allow_http_for_request
        end


        undef process_action

        ##
        # Override the default to enable auto-api behavior if desired.
        def process_action(method_name, *args) #:nodoc:
          if enable_auto_api?
            unless process_api_action(false, nil)
              super method_name, *args
            end
          else
            super method_name, *args
          end
        end

        rescue_from ::Incline::NotLoggedIn do |exception|
          flash[:info] = exception.message
          redirect_to incline.login_url
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
    # Authorizes access for the action.
    #
    # * With no arguments, this will validate that a user is currently logged in, but does not check their permission.
    # * With an argument of true, this will validate that the user currently logged in is an administrator.
    # * With one or more strings, this will validate that the user currently logged in has at least one or more
    #   of the named permissions.
    #
    #     authorize!
    #     authorize!(true)
    #     authorize!("Safety Manager", "HR Manager")
    #
    # If no user is logged in, then the user will be redirected to the login page and the method will return false.
    # If a user is logged in, but is not authorized, then the user will be redirected to the home page and the method
    # will return false.
    # If the user is authorized, the method will return true.
    def authorize!(*accepted_groups)

      true
    end

    ##
    # Is the current request for JSON data?
    #
    # Redirects are generally bad when JSON data is requested.
    # For instance a `create` request in JSON format should return data, not redirect to `show`.
    def json_request?
      request.format == :json || request.format == 'json'
    end

    ##
    # Override this to return true if you need to allow HTTP access for one or more actions of a controller.
    def allow_http_for_request
      false
    end

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
    def map_api_action(requested_action)
      requested_action
    end

    ##
    # If overridden to return true then the automatic parsing of the `action` parameter is enabled for all GET/POST requests.
    def enable_auto_api?
      false
    end

    ##
    # This method parses the `action` parameter passed either as a query parameter or a form parameter.
    #
    # The acton is then run through the `map_api_action` method.
    def process_api_action(raise_on_invalid_action = true, default_get_action = 'index')
      api_action =
          map_api_action(
              if request.post?
                # A post request can create, update, or destroy.
                # The post action can be provided as a query parameter or a form parameter with the form parameter
                # taking priority.
                {
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
        raise InvalidApiCall, 'Invalid API Action' if raise_on_invalid_action
        nil
      end
    end

    private

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

