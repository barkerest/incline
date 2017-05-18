require 'test_helper'

class RecaptchaValidatorTest < ActiveSupport::TestCase

  class TestModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :recaptcha

    validates :recaptcha, 'incline/recaptcha' => true
  end

  def setup
    @item = TestModel.new(recaptcha: Incline::Recaptcha::DISABLED)
  end

  test 'initial value should be valid' do
    assert @item.valid?
  end

  test 'recaptcha validator ignores blank values' do
    @item.recaptcha = nil
    assert @item.valid?
    @item.recaptcha = ''
    assert @item.valid?
    @item.recaptcha = '   '
    assert @item.valid?
  end

  test 'recaptcha validator has two error messages' do
    @item.recaptcha = '127.0.0.1' # no response
    assert_not @item.valid?
    assert @item.errors[:base].to_s =~ /requires recaptcha challenge to be completed/i

    @item.recaptcha = '127.0.0.1|invalid' # invalid response
    assert_not @item.valid?
    assert @item.errors[:base].to_s =~ /invalid response from recaptcha challenge/i

    # make sure it did not fail because of the IP address portion.
    @item.recaptcha = '127.0.0.1|disabled'
    assert @item.valid?
  end

  test 'recaptcha validator changes value' do
    assert_not_equal :verified, @item.recaptcha

    # the validator changes the value to :verified when it passes.
    assert @item.valid?
    assert_equal :verified, @item.recaptcha

    # that way future calls to valid? will continue to pass.
    assert @item.valid?
  end


end