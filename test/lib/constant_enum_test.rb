require 'test_helper'

class ConstantEnumTest < ActiveSupport::TestCase
  
  class MyEnum < ::Incline::ConstantEnum
    
    ALPHA = 1
    BRAVO = 2
    CHARLIE = 3
    DELTA = 4
    
  end
  
  test 'should allow initialization' do
    item = MyEnum.new(2)
    assert item
    assert_equal 2, item.value
    assert_equal 'BRAVO', item.name
    assert_equal item.name, item.to_s
  end
  
  test 'should not allow invalid values' do
    assert_raises ArgumentError do
      MyEnum.new(0)
    end
    assert_raises ArgumentError do
      MyEnum.new(5)
    end
  end
  
  test 'should be able to identify named values' do
    assert MyEnum.named?(3)
    assert_not MyEnum.named?(42)
  end
  
  test 'should always return a non-nil name' do
    assert_equal 'DELTA', MyEnum.name_for(4)
    assert_equal '', MyEnum.name_for(100)
  end
  
  
  
end