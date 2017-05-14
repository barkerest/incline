require 'test_helper'

class ActionControllerBaseExtensionsTest < ActiveSupport::TestCase

  test 'should have extension methods' do
    ac = ActionController::Base.new

    assert ac.respond_to?(:render_csv)
    assert ac.respond_to?(:redirect_back_or)
    assert ac.respond_to?(:store_location)

    assert ac.class.respond_to?(:enable_auto_api)
    assert ac.class.respond_to?(:disable_auto_api)
    assert ac.class.respond_to?(:auto_api?)
    assert ac.class.respond_to?(:allow_non_ssl)
    assert ac.class.respond_to?(:allow_anon)
    assert ac.class.respond_to?(:require_admin)

  end

end