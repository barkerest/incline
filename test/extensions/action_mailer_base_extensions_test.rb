require 'test_helper'

class ActionMailerBaseExtensionsTest < ActiveSupport::TestCase

  class TestMailer < ActionMailer::Base

  end

  test 'should have methods defined' do
    assert TestMailer.respond_to?(:default_hostname)
    assert TestMailer.respond_to?(:default_sender)
    assert TestMailer.respond_to?(:default_recipient)
  end

  test 'should have defaults set' do
    assert_equal TestMailer.default_sender, TestMailer.default[:from]
    assert_equal TestMailer.default_recipient, TestMailer.default[:to]
  end

end