<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :valid_user, except: [ :api ]
  before_action :set_<%= singular_table_name %>, only: [ :show, :edit, :update, :destroy ]


  # GET <%= route_url %>
  def index
    @dt_request = Incline::DataTablesRequest.new(params) do
      <%= orm_class.all(class_name) %>
    end
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    if @<%= orm_instance.save %>
      if json_request?
        render :show
      else
        redirect_after_edit @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully created.'" %>
      end
    else
      if json_request?
        @<%= singular_table_name %>.errors.add(:base, 'failed to save')
        render :show
      else
        render :new
      end
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      if json_request?
        render :show
      else
        redirect_after_edit @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully updated.'" %>
      end
    else
      if json_request?
        @<%= singular_table_name %>.errors.add(:base, 'failed to save')
        render :show
      else
        render :edit
      end
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    if json_request?
      render json: { data: <%= "'#{human_name} was successfully destroyed.'" %> }
    else
      redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully destroyed.'" %>
    end
  end

  # GET/POST <%= route_url %>/api?action=...
  def api
    process_api_action
  end

  private

  # Sends the client to the appropriate location after a successful update or create.
  # The default behavior with Rails is to redirect to the object itself.
  # The default behavior with Incline is to redirect to the list of objects.
  def redirect_after_edit(<%= singular_table_name %>, *status_messages)
    # Our behavior is to send the user back to the list on success.
    redirect_to <%= index_helper %>_url, *status_messages

    # Rails behavior is to send the user to the item itself.
    # Comment out the redirect above and uncomment this redirect to restore default behavior.
    # redirect_to <%= singular_table_name %>, *status_messages
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_<%= singular_table_name %>
    @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

  # Only allow a trusted parameter "white list" through.
  def <%= "#{singular_table_name}_params" %>
    <%- if attributes_names.empty? -%>
    params[:<%= singular_table_name %>]
    <%- else -%>
    params.require(:<%= singular_table_name %>).permit(<%= attributes_names.map { |name| ":#{name}" }.join(', ') %>)
    <%- end -%>
  end

end
<% end -%>
