require 'test_helper'

class InclineTest < ActiveSupport::TestCase

  test 'modules and classes loaded' do
    assert Object.const_defined? :Incline

    assert Incline.const_defined? :NotLoggedIn
    assert Incline.const_defined? :NotAuthorized
    assert Incline.const_defined? :InvalidApiCall

    assert Incline.const_defined? :VERSION
    assert Incline.const_defined? :Log
    assert Incline.const_defined? :Engine
    assert Incline.const_defined? :WorkPath
    assert Incline.const_defined? :JsonLogFormatter
    assert Incline.const_defined? :GlobalStatus
    assert Incline.const_defined? :DataTablesRequest
    assert Incline.const_defined? :DateTimeFormats
    assert Incline.const_defined? :NumberFormats
    assert Incline.const_defined? :Recaptcha
    assert Incline::Recaptcha.const_defined? :Tag

    assert Incline.const_defined? :Extensions
    assert Incline::Extensions.const_defined? :Object
    assert Incline::Extensions.const_defined? :Numeric
    assert Incline::Extensions.const_defined? :String
    assert Incline::Extensions.const_defined? :Application
    assert Incline::Extensions.const_defined? :ApplicationConfiguration
    assert Incline::Extensions.const_defined? :ActiveRecordBase
    assert Incline::Extensions.const_defined? :ConnectionAdapter
    assert Incline::Extensions.const_defined? :MainApp
    assert Incline::Extensions.const_defined? :ActionControllerBase
    assert Incline::Extensions.const_defined? :ActionViewBase
    assert Incline::Extensions.const_defined? :Session
    assert Incline::Extensions::Session.const_defined? :Common
    assert Incline::Extensions::Session.const_defined? :Controller
    assert Incline::Extensions.const_defined? :ErbScaffoldGenerator
    assert Incline::Extensions.const_defined? :JbuilderGenerator
    assert Incline::Extensions.const_defined? :JbuilderTemplate
    assert Incline::Extensions.const_defined? :TestCase
    assert Incline::Extensions.const_defined? :IntegerValue
    assert Incline::Extensions.const_defined? :FloatValue
    assert Incline::Extensions.const_defined? :TimeZoneConverter
    assert Incline::Extensions.const_defined? :DateTimeValue
    assert Incline::Extensions.const_defined? :DateValue
    assert Incline::Extensions.const_defined? :DecimalValue
    assert Incline::Extensions.const_defined? :FormBuilder

    assert Incline.const_defined? :EmailValidator
    assert Incline.const_defined? :SafeNameValidator
    assert Incline.const_defined? :IpAddressValidator
    assert Incline.const_defined? :RecaptchaValidator

    # Should not be loaded except by the 'incline' script.
    assert_not Incline.const_defined? :Cli
  end


end
