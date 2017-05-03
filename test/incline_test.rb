require 'test_helper'

class InclineTest < ActiveSupport::TestCase

  test 'modules and classes loaded' do
    assert Object.const_defined? :Incline

    assert Incline.const_defined? :VERSION
    assert Incline.const_defined? :Log
    assert Incline.const_defined? :Engine
    assert Incline.const_defined? :WorkPath
    assert Incline.const_defined? :JsonLogFormatter
    assert Incline.const_defined? :GlobalStatus
    assert Incline.const_defined? :DateTimeFormats

    assert Incline.const_defined? :Extensions
    assert Incline::Extensions.const_defined? :Object
    assert Incline::Extensions.const_defined? :Numeric
    assert Incline::Extensions.const_defined? :String
    assert Incline::Extensions.const_defined? :Application
    assert Incline::Extensions.const_defined? :ApplicationConfiguration
    assert Incline::Extensions.const_defined? :ActiveRecordBase
    assert Incline::Extensions.const_defined? :ConnectionAdapter
    assert Incline::Extensions.const_defined? :MainApp
    assert Incline::Extensions.const_defined? :ErbScaffoldGenerator
    assert Incline::Extensions.const_defined? :JbuilderGenerator
    assert Incline::Extensions.const_defined? :JbuilderTemplate
    assert Incline::Extensions.const_defined? :TestCase
    assert Incline::Extensions.const_defined? :IntegerValue
    assert Incline::Extensions.const_defined? :FloatValue
    assert Incline::Extensions.const_defined? :TimeZoneConverter
    assert Incline::Extensions.const_defined? :DateTimeValue
    assert Incline::Extensions.const_defined? :DateValue

    assert Incline.const_defined? :EmailValidator
    assert Incline.const_defined? :SafeNameValidator
    assert Incline.const_defined? :IpAddressValidator

    # Should not be loaded except by the 'incline' script.
    assert_not Incline.const_defined? :Cli
  end


end
