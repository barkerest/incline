require 'test_helper'

class StringExtensionsTest < ActiveSupport::TestCase

  test 'string has to_hex_string and to_byte_string' do
    s = 'hello'
    assert s.respond_to?(:to_hex_string)
    assert s.respond_to?(:to_byte_string)
  end

  test 'hex and byte conversion works' do
    s_text = 'Hello World'
    s_hex = '48656c6c6f20576f726c64'
    assert_equal s_hex, s_text.to_hex_string
    assert_equal s_text, s_hex.to_byte_string
    s_text += s_hex
    assert_equal s_text, s_text.to_hex_string.to_byte_string
  end

  test 'hex grouping works' do
    s_text = 'Hello World'
    s_hex = '48 65 6c 6c 6f 20 57 6f 72 6c 64'
    assert_equal s_hex, s_text.to_hex_string(true)
    assert_equal s_text, s_text.to_hex_string(true).to_byte_string
    s_hex = '486 56c 6c6 f20 576 f72 6c6 4'
    assert_equal s_hex, s_text.to_hex_string(3)
    assert_equal s_text, s_text.to_hex_string(3).to_byte_string
  end



end