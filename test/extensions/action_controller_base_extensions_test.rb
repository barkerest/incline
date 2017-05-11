require 'test_helper'

class ActionControllerBaseExtensionsTest < ActiveSupport::TestCase

  test 'should have extension methods' do
    ac = ActionController::Base.new

    assert ac.respond_to?(:render_csv)
    assert ac.respond_to?(:authorize!)
    assert ac.respond_to?(:json_request?)
    assert ac.respond_to?(:allow_http_for_request)
    assert ac.respond_to?(:map_api_action)
    assert ac.respond_to?(:enable_auto_api?)
    assert ac.respond_to?(:process_api_action)
    assert ac.respond_to?(:redirect_back_or)
    assert ac.respond_to?(:store_location)

  end

end