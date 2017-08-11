require 'test_helper'

<% module_namespacing do -%>
class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  setup do
    @<%= singular_table_name %> = <%= fixture_name %>(:one)
<% if mountable_engine? -%>
    @routes = Engine.routes
<% end -%>
    # Log in as the admin to ensure full access.
    # You may want to test accessibility separately.
    log_in_as incline_users(:admin)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create <%= singular_table_name %>" do
    # To avoid issues with uniqueness, we destroy the item first.
    @<%= singular_table_name %>.destroy
    
    # Now we should be able to create an item with the same info. 
    assert_difference('<%= class_name %>.count') do
      post :create, <%= "#{singular_table_name}: { #{attributes_hash} }" %>
    end

    assert_redirected_to <%= index_helper %>_path
  end

  test "should show <%= singular_table_name %>" do
    get :show, id: <%= "@#{singular_table_name}" %>
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: <%= "@#{singular_table_name}" %>
    assert_response :success
  end

  test "should update <%= singular_table_name %>" do
    patch :update, id: <%= "@#{singular_table_name}" %>, <%= "#{singular_table_name}: { #{attributes_hash} }" %>
    assert_redirected_to <%= index_helper %>_path
  end

  test "should destroy <%= singular_table_name %>" do
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, id: <%= "@#{singular_table_name}" %>
    end

    assert_redirected_to <%= index_helper %>_path
  end
end
<% end -%>
