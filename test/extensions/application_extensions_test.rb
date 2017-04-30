require 'test_helper'

class ApplicationExtensionsTest < ActiveSupport::TestCase

  test 'should have extension methods' do
    app = Rails.application
    skip unless app
    assert app.respond_to?(:running?)
    assert app.respond_to?(:app_name)
    assert app.respond_to?(:app_instance_name)
    assert app.respond_to?(:app_version)
    assert app.respond_to?(:app_company)
    assert app.respond_to?(:app_info)
    assert app.respond_to?(:app_copyright_year)
    assert app.respond_to?(:app_company)
    assert app.respond_to?(:restart_pending?)
    assert app.respond_to?(:request_restart!)
    assert app.respond_to?(:cookie_name)
  end

end