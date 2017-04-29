require 'test_helper'
require 'bigdecimal'

class NumericExtensionsTest < ActiveSupport::TestCase

  test 'numeric types have to_human' do
    assert Integer(123).respond_to?(:to_human)
    assert Float(123).respond_to?(:to_human)
    assert Rational(123).respond_to?(:to_human)
    assert BigDecimal.new(123).respond_to?(:to_human)
  end

  test 'integers convert as expected' do
    {
        1 => '1',
        10 => '10',
        100 => '100',
        1000 => '1 thousand',
        1500 => '1.5 thousand',
        1000000 => '1 million',
        1050000 => '1.05 million',
        1000000000 => '1 billion',
        1245000000 => '1.24 billion',   # banker's rounding, always rounds towards even for 0.5 (e.g. - 1.245 => 1.24, 1.255 => 1.26)
        1255000000 => '1.26 billion',
        999999999 => '1000 million',
        Integer('1234'.ljust(40,'0')) => '1.23 duodecillion'
    }.each do |v, s|
      assert_equal s, v.to_human
    end
  end

  test 'floats convert as expected' do
    {
        0.375 => '0.38',
        1.0 => '1',
        10.0 => '10',
        100.0 => '100',
        1000.0 => '1 thousand',
        1500.0 => '1.5 thousand',
        (1E36 + 1.0) => '1 undecillion'
    }.each do |v,s|
      assert_equal s, v.to_human
    end
  end

  test 'rationals convert as expected' do
    {
        Rational('3/8') => '3/8',
        Rational(1) => '1',
        Rational('5/3') => '5/3',
        Rational(10.0) => '10',
        Rational(100) => '100',
        Rational('100/1') => '100',
        Rational(1000) => '1 thousand',
        Rational(1500) => '1.5 thousand',
        Rational('1'.ljust(34,'0')) => '1 decillion'
    }.each do |v,s|
      assert_equal s, v.to_human
    end
  end

  test 'big_decimals convert as expected' do
    {
        BigDecimal(Rational('3/8'), 4) => '0.38',
        BigDecimal(1) => '1',
        BigDecimal(10) => '10',
        BigDecimal(100) => '100',
        BigDecimal(1000) => '1 thousand',
        BigDecimal(1500) => '1.5 thousand',
        BigDecimal('1'.ljust(31,'0')) => '1 nonillion'
    }.each do |v,s|
      assert_equal s, v.to_human
    end
  end

end