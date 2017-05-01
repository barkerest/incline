require 'test_helper'
require 'json'

class JbuilderTemplateExtensionsTest < ActiveSupport::TestCase

  class TestClass

    attr_reader :errors

    def initialize
      @errors = {
          :base => [ 'something bad happened' ],
          :name => 'is too long',
          :code => [ 'is not uppercase', 'is too long' ]
      }
    end
  end

  def setup
    @json = JbuilderTemplate.new(self)
    @item = TestClass.new
  end

  test 'has extension methods' do
    assert @json.respond_to?(:api_errors!)
  end

  test 'builds expected values' do
    @json.api_errors! 'test_class', @item.errors
    val = JSON.parse(@json.target!)

    assert val.is_a?(Hash)

    assert val['error'].is_a?(String)
    assert_equal 'Test class ' + @item.errors[:base].first, val['error']

    assert val['fieldErrors'].is_a?(Array)
    assert_equal 2, val['fieldErrors'].count
    e = val['fieldErrors'].find{|v| v['name'] == 'test_class.name'}
    assert e
    assert_equal 'Name is too long', e['status']
    e = val['fieldErrors'].find{|v| v['name'] == 'test_class.code'}
    assert e
    assert_equal "Code is not uppercase<br>\nCode is too long", e['status']
  end

end