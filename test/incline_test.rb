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

    assert Incline.const_defined? :ObjectExtensions
    assert Incline.const_defined? :NumericExtensions
    assert Incline.const_defined? :StringExtensions
    assert Incline.const_defined? :ApplicationExtensions
    assert Incline.const_defined? :ApplicationConfigurationExtensions
    assert Incline.const_defined? :ActiveRecordExtensions
    assert Incline.const_defined? :ConnectionAdapterExtension
    assert Incline.const_defined? :MainAppExtension
    assert Incline.const_defined? :ErbScaffoldGeneratorExtensions
    assert Incline.const_defined? :JbuilderGeneratorExtensions
    assert Incline.const_defined? :JbuilderTemplateExtensions
    assert Incline.const_defined? :TestCaseExtensions
    assert Incline.const_defined? :DateFormats
    assert Incline.const_defined? :IntegerValueExtensions
    assert Incline.const_defined? :FloatValueExtensions
    assert Incline.const_defined? :TimeZoneConverterExtensions
    assert Incline.const_defined? :DateTimeValueExtensions


    assert Incline.const_defined? :EmailValidator
    assert Incline.const_defined? :SafeNameValidator
    assert Incline.const_defined? :IpAddressValidator

    # Should not be loaded except by the 'incline' script.
    assert_not Incline.const_defined? :Cli
  end


end
