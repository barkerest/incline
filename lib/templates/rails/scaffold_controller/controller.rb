<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_dt_request, only: [ :index, :locate ]
  before_action :set_new_<%= singular_table_name %>, only: [ :new, :create ]
  before_action :set_<%= singular_table_name %>, only: [ :show, :edit, :update, :destroy ]

  layout :layout_to_use

  # GET <%= route_url %>
  def index
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    if @<%= orm_instance.save %>
      handle_update_success notice: <%= "'#{human_name} was successfully created.'" %>
    else
      handle_update_failure :new
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      handle_update_success notice: <%= "'#{human_name} was successfully updated.'" %>
    else
      handle_update_failure :edit
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    handle_update_success notice: <%= "'#{human_name} was successfully destroyed.'" %>
  end

  # GET/POST <%= route_url %>/api?action=...
  def api
    process_api_action
  end

  # POST <%= route_url %>/1/locate
  def locate
    render json: { record: @dt_request.record_location }
  end

private

  # Inline requests do not get a layout, otherwise use the default layout.
  def layout_to_use
    inline_request? ? false : nil
  end

  def handle_update_failure(action)
    if json_request?
      # add a model-level error and render the json response.
      @<%= singular_table_name %>.errors.add(:base, 'failed to save')
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
      redirect_to <%= index_helper %>_url, *messages
    end
  end

  # Only allow a trusted parameter "white list" through.
  def <%= "#{singular_table_name}_params" %>
    if params.include?(:<%= singular_table_name %>)
      <%- if attributes_names.empty? -%>
      params[:<%= singular_table_name %>]
      <%- else -%>
      params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
      <%- end -%>
    else
      { }
    end
  end

  # Assigns the variable used for index and locate actions.
  def set_dt_request
    @dt_request = Incline::DataTablesRequest.new(params) do
      <%= orm_class.all(class_name) %>
    end
  end

  # Assigns the variable used for new and create actions.
  def set_new_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>
  end

  # Assigns the variable used for every other action.
  def set_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

end
<% end -%>
