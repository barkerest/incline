require 'test_helper'

class BitEnumTest < ActiveSupport::TestCase
  
  class MyEnum < ::Incline::BitEnum
    
    # raw bits.
    ALPHA = 1
    BRAVO = 2
    CHARLIE = 4
    DELTA = 8
    ECHO = 16
    
    # combined bits.
    FOXTROT = 5
    GOLF = 17
    
  end
  
  test 'should allow initialization' do
    item = MyEnum.new(6)
    assert item
    assert_equal 6, item.value
    assert_equal %w(BRAVO CHARLIE), item.name
    assert_equal 'BRAVO | CHARLIE', item.to_s
  end
  
  test 'should not allow invalid values' do
    assert_raises(ArgumentError){ MyEnum.new(0) }
    assert_raises(ArgumentError){ MyEnum.new(32) }
  end
  
  test 'should allow valid values' do
    assert MyEnum.new(1)
    assert MyEnum.new(7)
    assert MyEnum.new(15)
    assert MyEnum.new(31)
  end
  
  test 'should recognize names' do
    assert MyEnum.named?(1)
    assert MyEnum.named?(2)
    assert MyEnum.named?(3)
    assert MyEnum.named?(4)
    assert MyEnum.named?(5)
    assert_equal %w(ALPHA), MyEnum.name_for(1)
    assert_equal %w(BRAVO), MyEnum.name_for(2)
    assert_equal %w(ALPHA BRAVO), MyEnum.name_for(3)
    assert_equal %w(CHARLIE), MyEnum.name_for(4)
    assert_equal %w(FOXTROT), MyEnum.name_for(5)
  end
  
  
end