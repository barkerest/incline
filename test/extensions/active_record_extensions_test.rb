require 'test_helper'

class ActiveRecordExtensionsTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.rand(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  def setup
    # Create a test table.
    silence_stream STDOUT do
      ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
        t.string :name
      end
    end

    # And then create a test model.
    eval <<-EOM
class #{TEST_TABLE_CLASS} < ActiveRecord::Base
  self.table_name = #{TEST_TABLE_NAME.inspect}
end
    EOM

    # Store the model class for use.
    @model_class = self.class.const_get TEST_TABLE_CLASS

    # Add a few records just to have something to play with.
    @model_class.create name: 'Item 1'
    @model_class.create name: 'Item 2'
    @model_class.create name: 'Item 3'
    @model_class.create name: 'Item 2'  # one duplicate name...
  end

  def teardown
    # Undefine the model class (or at least remove it from the Object namespace).
    self.class.send :remove_const, TEST_TABLE_CLASS

    # Remove the table from the database.
    silence_stream STDOUT do
      ActiveRecord::Migration::drop_table TEST_TABLE_NAME
    end
  end

  test 'has extension methods' do
    assert @model_class.respond_to?(:get_id)
    assert @model_class.respond_to?(:get)
    assert @model_class.respond_to?('[]')
  end

  test 'to_s and inspect are overridden' do
    item = @model_class.first
    assert_equal item.name, item.to_s
    assert_equal "#<#{item.class}:#{item.object_pointer} #{item.to_s}>", item.inspect
  end

  test 'get_id returns ids' do
    item = @model_class.first
    # recognize a model and return the ID.
    assert_equal item.id, @model_class.get_id(item)

    # return the integer value unmodified.
    assert_equal item.id, @model_class.get_id(item.id)

    # recognize an integer string and return the integer value.
    assert_equal item.id, @model_class.get_id(item.id.to_s)

    # locate the item by name and return the ID.
    assert_equal item.id, @model_class.get_id(item.name)

    # do it all again with arrays.
    assert_equal [ item.id ], @model_class.get_id([ item ])
    assert_equal [ item.id ], @model_class.get_id([ item.id ])
    assert_equal [ item.id ], @model_class.get_id([ item.id.to_s ])
    assert_equal [ item.id ], @model_class.get_id([ item.name ])

    # does not validate integers.
    assert_equal 99, @model_class.get_id(99)

    # Searches by :code and :name attributes if the model has them.
    # This is apparent where we are searching with the item name.
    # However if the name doesn't match, nil should be returned.
    assert_nil @model_class.get_id('Item 4')
  end

  test 'get works as expected' do
    # get() will always return an array unless there are no results.
    # It will search by :code and :name attributes if the model has them.

    # There should be two items named 'Item 2'.
    ids = @model_class.get_id('Item 2')
    assert_equal 2, ids.count

    items = @model_class.get('Item 2')
    assert items
    assert_equal 2, items.count
    assert_equal ids, items.map{|i| i.id}

    items = @model_class.get(ids)
    assert items
    assert_equal 2, items.count
    assert_equal ids, items.map{|i| i.id}

    # There should only be one item named 'Item 3'.
    ids = @model_class.get_id('Item 3')
    assert ids.is_a?(Integer)

    items = @model_class.get('Item 3')
    assert items
    assert_equal 1, items.count
    assert_equal ids, items.first.id

    items = @model_class.get(ids)
    assert items
    assert_equal 1, items.count
    assert_equal ids, items.first.id

    # Should allow an array as an argument.
    items = @model_class.get(['Item 1', 'Item 3'])
    assert items
    assert_equal 2, items.count
    assert items.find{|i| i.name == 'Item 1'}
    assert items.find{|i| i.name == 'Item 3'}

    # There should be no item named 'Item 4'.
    assert_nil @model_class.get('Item 4')

    # There should be no ID of 99.
    assert_nil @model_class.get(99)
  end

  test '[] works as expected' do
    # [] will always return one item if any items are found or nil if none are found.
    # It will search by :code and :name attributes if the model has them.

    # There should be two items named 'Item 2'.
    # But [] will only return the first, sorted by ID since the name is the same.
    ids = @model_class.get_id('Item 2')
    assert_equal 2, ids.count

    item = @model_class['Item 2']
    assert item
    assert_equal ids.first, item.id

    # Even when an array is used for the argument, only one item will be returned.
    item = @model_class[ids]
    assert item
    assert_equal ids.first, item.id

    # There should only be one item named 'Item 3'.
    id = @model_class.get_id('Item 3')
    assert id.is_a?(Integer)

    item = @model_class['Item 3']
    assert item
    assert_equal id, item.id

    item = @model_class[id]
    assert item
    assert_equal id, item.id

    # Should allow an array as an argument, but only the first item will be returned.
    item = @model_class[['Item 1', 'Item 3']]
    assert item
    assert_equal @model_class.get_id('Item 1'), item.id

    # There should be no item named 'Item 4'.
    assert_nil @model_class['Item 4']

    # There should be no ID of 99.
    assert_nil @model_class[99]
  end


end