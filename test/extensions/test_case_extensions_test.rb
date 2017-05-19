require 'test_helper'

class TestCaseExtensionsTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  def setup
    # Create a test table.
    silence_stream STDOUT do
      ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
        t.integer :group,       null: false
        t.string  :name,        null: false,  limit: 30
        t.string  :description,               limit: 100
      end
    end

    # And then create a test model.
    eval <<-EOM
class #{TEST_TABLE_CLASS} < ActiveRecord::Base
  self.table_name = #{TEST_TABLE_NAME.inspect}

  attr_accessor :recaptcha, :email, :ip_any, :ip_mask, :ip_nomask, :session, :safe_name

  validates :group,
      presence: true

  validates :name,
      presence: true,
      length: { minimum: 5, maximum: 30 },
      uniqueness: { case_sensitive: false, scope: :group }

  validates :description,
      length: { maximum: 100 }

  validates :recaptcha, 'incline/recaptcha' => true
  validates :email, 'incline/email' => true
  validates :ip_any, 'incline/ip_address' => true
  validates :ip_mask, 'incline/ip_address' => { require_mask: true }
  validates :ip_nomask, 'incline/ip_address' => { no_mask: true }
  validates :safe_name, 'incline/safe_name' => true
end
    EOM

    # Store the model class for use.
    @model_class = self.class.const_get TEST_TABLE_CLASS
    @item = @model_class.new(group: 1, name: 'Hello', description: 'World', session: 99, email: 'user@example.com', recaptcha: Incline::Recaptcha::DISABLED)
  end

  def teardown
    # Undefine the model class (or at least remove it from the Object namespace).
    self.class.send :remove_const, TEST_TABLE_CLASS

    # Remove the table from the database.
    silence_stream STDOUT do
      ActiveRecord::Migration::drop_table TEST_TABLE_NAME
    end
  end

  test 'have extension methods' do
    assert respond_to?(:is_logged_in?)
    assert respond_to?(:log_in_as)
    assert respond_to?(:assert_required)
    assert respond_to?(:assert_max_length)
    assert respond_to?(:assert_min_length)
    assert respond_to?(:assert_uniqueness)
    assert respond_to?(:assert_recaptcha_validation)
    assert respond_to?(:assert_email_validation)
    assert respond_to?(:assert_ip_validation)
    assert respond_to?(:assert_safe_name_validation)
  end

  test 'item should be valid' do
    assert @item.valid?
  end

  test 'item should require group' do
    assert_required @item, :group
  end

  test 'item should require name' do
    assert_required @item, :name
  end

  test 'item name should have min length' do
    assert_min_length @item, :name, 5
  end

  test 'item name should have max length' do
    assert_max_length @item, :name, 30
  end

  test 'item name should be unique within group' do
    assert_uniqueness @item, :name, group: 2
  end

  test 'item description should have max length' do
    assert_max_length @item, :description, 100
  end

  test 'item recaptcha should pass validation' do
    assert_recaptcha_validation @item, :recaptcha
  end

  test 'item email should pass validation' do
    assert_email_validation @item, :email
  end

  test 'item ips should pass validation' do
    assert_ip_validation @item, :ip_any
    assert_ip_validation @item, :ip_mask, :require_mask
    assert_ip_validation @item, :ip_nomask, :deny_mask
  end

  test 'item safe_name should pass validation' do
    assert_safe_name_validation @item, :safe_name, 10
  end

  test 'item description should not be required' do
    assert_raises(Minitest::Assertion) { assert_required @item, :description }
  end

  test 'item session should not be required' do
    assert_raises(Minitest::Assertion) { assert_required @item, :session }
  end

  test 'item description length is not limited to 50, 101, or 10' do
    assert_raises(Minitest::Assertion) { assert_max_length @item, :description, 50 }
    assert_raises(Minitest::Assertion) { assert_max_length @item, :description, 101 }
    assert_raises(Minitest::Assertion) { assert_min_length @item, :description, 10 }
  end

  test 'item name is unique across sessions' do
    assert_raises(Minitest::Assertion) { assert_uniqueness @item, :name, session: 100 }
  end

  test 'item description is not a recaptcha field' do
    assert_raises(Minitest::Assertion) { assert_recaptcha_validation @item, :description }
  end

  test 'item description is not an ip address field' do
    assert_raises(Minitest::Assertion) { assert_ip_validation @item, :description }
  end

  test 'item description is not an email address field' do
    assert_raises(Minitest::Assertion) { assert_email_validation @item, :description }
  end

  test 'item description is not a safe name field' do
    assert_raises(Minitest::Assertion) { assert_safe_name_validation @item, :description }
  end

end