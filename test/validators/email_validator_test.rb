require 'test_helper'

class EmailValidatorTest < ActiveSupport::TestCase

  class TestModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :email

    validates :email, 'incline/email' => true
  end

  def setup
    @item = TestModel.new(email: 'tester@example.com')
  end

  test 'initial value should be valid' do
    assert @item.valid?
  end

  test 'email validator ignores blank values' do
    @item.email = nil
    assert @item.valid?
    @item.email = ''
    assert @item.valid?
    @item.email = '   '
    assert @item.valid?
  end

  test 'should accept valid addresses' do
    valid = %w(
        user@example.com
        USER@foo.COM
        A_US-ER@foo.bar.org
        first.last@foo.jp
        alice+bob@bax.cn
    )

    valid.each do |address|
      @item.email = address
      assert @item.valid?, "#{address.inspect} should be valid"
    end
  end

  test 'should reject invalid addresses' do
    invalid = %w(
        user@example,com
        user_at_foo.org
        user@example.
        user@example.com.
        foo@bar_baz.com
        foo@bar+baz.com
        @example.com
        user@
        user
        user@..com
        user@example..com
        user@.example.com
        user@@example.com
        user@www@example.com
    )

    invalid.each do |address|
      @item.email = address
      assert_not @item.valid?, "#{address.inspect} should not be valid"
    end
  end

end