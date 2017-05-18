require 'test_helper'

module Incline
  class ContactMessageTest < ActiveSupport::TestCase

    def setup
      @item = Incline::ContactMessage.new(
          your_name: 'Jane Doe',
          your_email: 'janed@example.com',
          related_to: 'Other',
          subject: 'Just a test',
          body: 'This is just a test message.',
          recaptcha: Incline::Recaptcha::DISABLED
      )
    end

    test 'should be valid' do
      assert @item.valid?
    end

    test 'should require your_name' do
      assert_required @item, :your_name
    end

    test 'should require your_email' do
      assert_required @item, :your_email
    end

    test 'should require related_to' do
      assert_required @item, :related_to
    end

    test 'should require subject when related_to is other' do
      @item.related_to = 'other'
      assert_required @item, :subject
    end

    test 'should not require subject when related_to is anything else' do
      @item.related_to = 'something'
      assert @item.valid?
      @item.subject = nil
      assert @item.valid?
      @item.subject = ''
      assert @item.valid?
      @item.subject = '   '
      assert @item.valid?
    end

    test 'should require body' do
      assert_required @item, :body
    end

    test 'should require recaptcha' do
      assert_required @item, :recaptcha
    end

    test 'should validate recaptcha' do
      assert_recaptcha @item, :recaptcha
    end

    test 'should reject invalid email addresses' do
      [ # just a few sanity checks, the email validator checks are more thorough but we want to ensure the validator is running.
          'admin',
          'user@localhost'
      ].each do |addr|
        @item.your_email = addr
        assert_not @item.valid?, "Should not have accepted #{addr.inspect}."
      end
    end


  end
end