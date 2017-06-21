module Incline
  class AccessGroupsController < ApplicationController

    before_action :set_access_group, only: [ :show, :edit, :update, :destroy ]
    before_action :set_dt_request, only: [ :index, :locate ]

    require_admin true

    layout :layout_to_use

    ##
    # GET /incline/access_groups
    def index
    end

    ##
    # GET /incline/access_groups/1
    def show
    end

    ##
    # GET /incline/access_groups/new
    def new
      @access_group = Incline::AccessGroup.new
    end

    ##
    # GET /incline/access_groups/1/edit
    def edit
    end

    ##
    # POST /incline/access_groups
    def create
      @access_group = Incline::AccessGroup.create(access_group_params :before_create)
      if @access_group
        if @access_group.update(access_group_params :after_create)
          handle_update_success notice: 'Access group was successfully created.'
        else
          handle_update_failure :new
        end
      else
        handle_update_failure :new
      end
    end

    ##
    # PATCH/PUT /incline/access_groups/1
    def update
      if @access_group.update(access_group_params)
        handle_update_success notice: 'Access group was successfully updated.'
      else
        handle_update_failure :edit
      end
    end

    ##
    # DELETE /incline/access_groups/1
    def destroy
      @access_group.destroy
      handle_update_success notice: 'Access group was successfully destroyed.'
    end

    # POST /incline/access_groups/1/locate
    def locate
      render json: { record: @dt_request.record_location }
    end

    # GET/POST /incline/access_groups/api?action=...
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
      if inline_request?
        # inline and json requests expect json on success.
        render 'show', formats: [ :json ]
      else
        # otherwise, we redirect.

        # The default behavior in rails is to redirect to the item that was updated.
        # The default behavior in incline is to redirect to the item collection.

        # To reinstate the default rails behavior, uncomment the line below.
        # redirect_to @<%= singular_table_name %>, *messages unless @<%= singular_table_name %>.destroyed?
        redirect_to access_groups_url, *messages
      end
    end

    def set_dt_request
      @dt_request = Incline::DataTablesRequest.new(params) do
        Incline::AccessGroup.all
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_access_group
      @access_group = Incline::AccessGroup.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def access_group_params(mode = :all)
      list = []
      list += [ :name ] if mode == :before_create || mode == :all
      list += [ { group_ids: [], user_ids: [] } ] if mode == :after_create || mode == :all

      params.require(:access_group).permit(list)
    end
  end
end
