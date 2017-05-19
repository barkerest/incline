require 'test_helper'

class TimeZoneConverterExtensionsTest < ActiveSupport::TestCase

  # The effects of the extensions should be felt in other tests, this one simply verifies that the extension has been included.
  test 'should include TimeZoneConverter extension' do
    assert ActiveRecord::AttributeMethods::TimeZoneConversion::TimeZoneConverter.include? Incline::Extensions::TimeZoneConverter
  end

end