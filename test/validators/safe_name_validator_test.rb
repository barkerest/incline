require 'test_helper'

class SafeNameValidatorTest < ActiveSupport::TestCase

  class TestModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :name

    validates :name, 'incline/safe_name' => true
  end

  def setup
    @item = TestModel.new(name: 'hello_world')
  end

  test 'initial value should be valid' do
    assert @item.valid?
  end

  test 'value can be in any case' do
    @item.name = 'HELLO_WORLD'
    assert @item.valid?
    @item.name = 'Hello_World'
    assert @item.valid?
    @item.name = 'hello_WORLD'
    assert @item.valid?
  end

  test 'safe_name validator ignores blank values' do
    @item.name = nil
    assert @item.valid?
    @item.name = ''
    assert @item.valid?
    @item.name = '   '
    assert @item.valid?
  end

  test 'should accept valid names' do
    %w(
        abcd
        a_b_c_d
        abc123
        alpha_beta_1_2_3
        alpha_beta___123
    ).each do |name|
      @item.name = name
      assert @item.valid?, "should accept '#{name}'"
    end
  end

  test 'should reject invalid names' do
    safe = @item.name
    [
        '123',
        '_abc123',
        ' abc123',
        '=abc123',
        '+abc123',
        '-abc123',
        ':abc123',
        '@abc123',
        '$abc123'
    ].each do |name|
      @item.name = name
      assert_not @item.valid?, "should not accept '#{name}'"
      assert @item.errors[:name].to_s =~ /must start with a letter/i, "name '#{name}' did not fail for the expected reason"
      @item.name = safe
      assert @item.valid?
    end
    [
      'abc_',
      'abc_123_',
      'abc 123_'
    ].each do |name|
      @item.name = name
      assert_not @item.valid?, "should not accept '#{name}'"
      assert @item.errors[:name].to_s =~ /must not end with an underscore/i, "name '#{name}' did not fail for the expected reason"
      @item.name = safe
      assert @item.valid?
    end
    [
        'abc 123',
        'a b c d',
        'abc123?',
        'abc123!',
        'abc_123(0)',
        'abc,123',
        'abc-123'
    ].each do |name|
      @item.name = name
      assert_not @item.valid?, "should not accept '#{name}'"
      assert @item.errors[:name].to_s =~ /must contain only letters, numbers, and underscore/i, "name '#{name}' did not fail for the expected reason"
      @item.name = safe
      assert @item.valid?
    end

  end

end