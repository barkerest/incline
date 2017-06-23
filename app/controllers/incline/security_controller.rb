module Incline
  class SecurityController < ApplicationController

    before_action :set_dt_request, only: [ :index, :locate ]
    before_action :set_security, only: [ :show, :edit, :update ]

    require_admin true

    layout :layout_to_use

    ##
    # GET /incline/security
    def index
      @lists = {}
      unless @dt_request.provided?
        Incline::ActionSecurity.valid_items   # ensure only valid items are in the database.

        # build lists for the dropdown filters.
        @lists[:controller_name] = Incline::ActionSecurity.visible.pluck(:controller_name).uniq.sort
        @lists[:action_name] = Incline::ActionSecurity.visible.pluck(:action_name).uniq.sort
        @lists[:short_permitted] = Incline::ActionSecurity::SHORT_PERMITTED_FILTERS
      end
    end

    ##
    # GET /incline/security/1
    def show
    end

    ##
    # GET /incline/security/1/edit
    def edit
    end

    ##
    # PATCH/PUT /incline/security/1
    def update
      if @security.update(security_params)
        handle_update_success notice: 'Action security was successfully updated.'
      else
        handle_update_failure :edit
      end
    end

    # POST /incline/security/1/locate
    def locate
      render json: { record: @dt_request.record_location }
    end

    # GET/POST /incline/security/api?action=...
    def api
      process_api_action
    end

    private

    def layout_to_use
      inline_request? ? false : nil
    end

    def handle_update_failure(action)
      if json_request?
        # add a model-level error and render the json response.
        @access_group.errors.add(:base, 'failed to save')
        render 'show', formats: [ :json ]
      else
        # render the appropriate action.
        render action
      end
    end

    def handle_update_success(*messages)
      # reload the cache from the database.
      Incline::ActionSecurity.valid_items true, false

      if inline_request?
        # inline and json requests expect json on success.
        render 'show', formats: [ :json ]
      else
        # otherwise, we redirect.
        redirect_to index_security_url, *messages
      end
    end

    def set_dt_request
      @dt_request = Incline::DataTablesRequest.new(params.merge(force_regex: true)) do
        Incline::ActionSecurity.visible
      end
    end

    def set_security
      @security = Incline::ActionSecurity.find(params[:id])
    end

    def security_params
      params.require(:action_security).permit(group_ids: [])
    end

  end
end
