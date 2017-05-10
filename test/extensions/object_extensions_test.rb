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

  test 'all objects have to_bool method' do
    assert Object.respond_to?(:to_bool)
    assert Object.new.respond_to?(:to_bool)
    assert 'hello'.respond_to?(:to_bool)
    assert 12345.respond_to?(:to_bool)
    assert [1, 2, 3].respond_to?(:to_bool)
    assert Hash.new(hello: :world).respond_to?(:to_bool)
    assert true.respond_to?(:to_bool)
    assert false.respond_to?(:to_bool)
    assert nil.respond_to?(:to_bool)
  end


  test 'object_pointer_is_formatted_correctly' do
    item = Object.new
    expected = '0x' + item.object_id.to_s(16).rjust(12,'0').downcase
    assert_equal expected, item.object_pointer
  end


  test 'to_bool works as expected' do
    # normal true/false
    assert true.to_bool
    assert_not false.to_bool

    # nil => false  (should not return nil!)
    assert_not nil.to_bool
    assert_not_nil nil.to_bool

    # symbols
    assert :true.to_bool
    assert_not :false.to_bool
    assert :yes.to_bool
    assert_not :no.to_bool
    assert :on.to_bool
    assert_not :off.to_bool

    # integers
    assert_not 0.to_bool
    assert 1.to_bool
    assert -1.to_bool

    # floats
    assert_not 0.0.to_bool
    assert 0.1.to_bool
    assert 1.0.to_bool

    # strings (expected true values)
    assert 'true'.to_bool
    assert 'True'.to_bool
    assert 'TRUE'.to_bool
    assert 't'.to_bool
    assert 'T'.to_bool
    assert 'yes'.to_bool
    assert 'Yes'.to_bool
    assert 'YES'.to_bool
    assert 'y'.to_bool
    assert 'Y'.to_bool
    assert 'on'.to_bool
    assert 'On'.to_bool
    assert 'ON'.to_bool
    assert '1'.to_bool

    # strings (expected false values)
    assert_not ''.to_bool
    assert_not 'false'.to_bool
    assert_not 'False'.to_bool
    assert_not 'FALSE'.to_bool
    assert_not 'f'.to_bool
    assert_not 'F'.to_bool
    assert_not 'no'.to_bool
    assert_not 'No'.to_bool
    assert_not 'NO'.to_bool
    assert_not 'off'.to_bool
    assert_not 'Off'.to_bool
    assert_not 'OFF'.to_bool
    assert_not '0'.to_bool

    # strings (misc values are all false)
    assert_not 'hello'.to_bool
    assert_not 'maybe'.to_bool
    assert_not 'true-ish'.to_bool
    assert_not '123'.to_bool

    # other values
    assert_not Object.to_bool
    assert_not Object.new.to_bool
  end


end