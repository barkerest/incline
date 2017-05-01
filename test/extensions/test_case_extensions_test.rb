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
        t.integer :session
        t.string  :description,               limit: 100
      end
    end

    # And then create a test model.
    eval <<-EOM
class #{TEST_TABLE_CLASS} < ActiveRecord::Base
  self.table_name = #{TEST_TABLE_NAME.inspect}

  validates :group,
      presence: true

  validates :name,
      presence: true,
      length: { minimum: 5, maximum: 30 },
      uniqueness: { case_sensitive: false, scope: :group }

  validates :description,
      length: { maximum: 100 }

end
    EOM

    # Store the model class for use.
    @model_class = self.class.const_get TEST_TABLE_CLASS
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
  end

  test 'validators work correctly' do
    @item = @model_class.new(group: 1, name: 'Hello', description: 'World', session: 99)

    assert @item.valid?

    # should pass.
    assert_required @item, :group
    assert_required @item, :name
    assert_min_length @item, :name, 5
    assert_max_length @item, :name, 30
    assert_uniqueness @item, :name, group: 2
    assert_max_length @item, :description, 100

    # should fail.
    assert_raises(Minitest::Assertion) { assert_required @item, :description }
    assert_raises(Minitest::Assertion) { assert_required @item, :session }
    assert_raises(Minitest::Assertion) { assert_max_length @item, :description, 50 }
    assert_raises(Minitest::Assertion) { assert_max_length @item, :description, 101 }
    assert_raises(Minitest::Assertion) { assert_min_length @item, :description, 10 }
    assert_raises(Minitest::Assertion) { assert_uniqueness @item, :name, session: 100 }
  end

  # TODO: Test is_logged_in? and log_in_as.

end