require 'test_helper'

class ObjectExtensionsTest < ActiveSupport::TestCase

  test 'all objects have object_pointer method' do
    assert Object.respond_to?(:object_pointer)
    assert Object.new.respond_to?(:object_pointer)
    assert 'hello'.respond_to?(:object_pointer)
    assert 12345.respond_to?(:object_pointer)
    assert [1, 2, 3].respond_to?(:object_pointer)
    assert Hash.new(hello: :world).respond_to?(:object_pointer)
  end

  test 'object_pointer_is_formatted_correctly' do
    item = Object.new
    expected = '0x' + item.object_id.to_s(16).rjust(12,'0').downcase
    assert_equal expected, item.object_pointer
  end


end