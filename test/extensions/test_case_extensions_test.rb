require 'test_helper'

class TestCaseExtensionsTest < ActiveSupport::TestCase

  test 'have extension methods' do
    assert respond_to?(:is_logged_in?)
    assert respond_to?(:log_in_as)
    assert respond_to?(:run_date_field_tests)
    assert respond_to?(:assert_required)
    assert respond_to?(:assert_max_length)
    assert respond_to?(:assert_min_length)
    assert respond_to?(:assert_uniqueness)
  end

  # TODO: Test the methods to ensure they work as expected.

end