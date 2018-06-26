require 'test_helper'

class DataTablesRequestTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  def setup
    # Create a test table.
    silence_stream STDOUT do
      ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
        t.string  :name,              null: false,  limit: 100
        t.string  :classification,                  limit: 100
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

    @model_class.create! name: 'Fred Flintstone', classification: 'Cartoon Character'
    @model_class.create! name: 'Barney Rubble', classification: 'Cartoon Character'
    @model_class.create! name: 'Homer Simpson', classification: 'Cartoon Character'
    @model_class.create! name: 'Percy Jackson', classification: 'Book Character'
    @model_class.create! name: 'Harry Potter', classification: 'Book Character'
    @model_class.create! name: 'George Washington', classification: 'Historical Figure'
    @model_class.create! name: 'Albert Einstein', classification: 'Historical Figure'

    @columns = [
        { data: 'dt_name', name: 'name', searchable: true, orderable: true },
        { data: 'dt_class', name: 'classification', searchable: true, orderable: true },
    ]

  end

  def teardown
    # Undefine the model class (or at least remove it from the Object namespace).
    self.class.send :remove_const, TEST_TABLE_CLASS

    # Remove the table from the database.
    silence_stream STDOUT do
      ActiveRecord::Migration::drop_table TEST_TABLE_NAME
    end
  end

  test 'should flag as not provided' do
    request = Incline::DataTablesRequest.new do
      @model_class.all
    end
    assert_not request.provided?
  end

  test 'should require a block' do
    assert_raises ::ArgumentError do
      Incline::DataTablesRequest.new
    end
  end

  test 'should retrieve all records' do
    request = Incline::DataTablesRequest.new(
        draw: 1,
        start: 0,
        length: 5,
        columns: @columns
    ) do
      @model_class.all
    end
    assert request.provided?
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 1, request.draw
    assert_equal 7, request.records_total
    assert_equal 7, request.records_filtered
    assert_equal 5, request.records.count
    assert_equal 'Fred Flintstone', request.records.first.name

    request = Incline::DataTablesRequest.new(
        draw: 10,
        start: 5,
        length: 5,
        columns: @columns
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 10, request.draw
    assert_equal 7, request.records_total
    assert_equal 7, request.records_filtered
    assert_equal 2, request.records.count
    assert_equal 'George Washington', request.records.first.name
  end

  test 'should honor the ordering' do
    request = Incline::DataTablesRequest.new(
        draw: 2,
        start: 0,
        length: 5,
        columns: @columns,
        order: [ { column: 0, dir: 'asc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 2, request.draw
    assert_equal 'Albert Einstein', request.records.first.name

    request = Incline::DataTablesRequest.new(
        draw: 2,
        start: 0,
        length: 5,
        columns: @columns,
        order: [ { column: 1, dir: 'asc' }, { column: 0, dir: 'asc' } ]
    ) do
      @model_class.all
    end
    assert_equal 'Harry Potter', request.records.first.name
  end

  test 'should search by text' do
    request = Incline::DataTablesRequest.new(
        draw: 3,
        start: 0,
        length: 5,
        columns: @columns,
        search: { value: 'toon', regex: false },
        order: [ { column: 0, dir: 'asc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 3, request.draw
    assert_equal 7, request.records_total
    assert_equal 3, request.records_filtered
    assert_equal 3, request.records.count
    assert_equal 'Barney Rubble', request.records.first.name

    c = @columns.dup
    c[0][:search] = { value: 'ar', regex: false }
    request = Incline::DataTablesRequest.new(
        draw: 3,
        start: 0,
        length: 5,
        columns: c,
        order: [ { column: 0, dir: 'desc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 7, request.records_total
    assert_equal 2, request.records_filtered
    assert_equal 2, request.records.count
    assert_equal 'Harry Potter', request.records.first.name
  end

  test 'should search by regex' do
    request = Incline::DataTablesRequest.new(
        draw: 4,
        start: 0,
        length: 5,
        columns: @columns,
        search: { value: /book/i, regex: true },
        order: [ { column: 0, dir: 'asc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 4, request.draw
    assert_equal 7, request.records_total
    assert_equal 2, request.records_filtered
    assert_equal 2, request.records.count
    assert_equal 'Harry Potter', request.records.first.name

    c = @columns.dup
    c[0][:search] = { value: /[ts]on/i, regex: true }
    request = Incline::DataTablesRequest.new(
        draw: 4,
        start: 0,
        length: 5,
        columns: c,
        order: [ { column: 0, dir: 'desc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 7, request.records_total
    assert_equal 4, request.records_filtered
    assert_equal 4, request.records.count
    assert_equal 'Percy Jackson', request.records.first.name
  end

  test 'should handle errors' do
    request = Incline::DataTablesRequest.new(
        draw: 5,
        start: 0,
        length: 5,
        columns: @columns
    ) do
      raise 'Uh oh, something bad happened.'
    end

    assert request.provided?
    assert request.error?
    assert_equal 'Uh oh, something bad happened.', request.error
    assert_equal 5, request.draw
    assert_equal 0, request.records_total
    assert_equal 0, request.records_filtered
    assert_equal 0, request.records.count
  end

  test 'should refresh' do
    request = Incline::DataTablesRequest.new(
        draw: 6,
        start: 0,
        length: 5,
        columns: @columns,
        search: { value: 'toon', regex: false },
        order: [ { column: 0, dir: 'desc' } ]
    ) do
      @model_class.all
    end
    assert_not request.error?, "Did not expect #{request.error.inspect}"
    assert_equal 6, request.draw
    assert_equal 7, request.records_total
    assert_equal 3, request.records_filtered
    assert_equal 3, request.records.count
    assert_equal 'Homer Simpson', request.records.first.name

    @model_class.create name: 'Lisa Simpson', classification: 'Cartoon Character'
    assert_nil request.records.find{|i| i.name == 'Lisa Simpson'}

    assert_equal request, request.refresh!
    assert_equal 6, request.draw
    assert_equal 8, request.records_total
    assert_equal 4, request.records_filtered
    assert_equal 4, request.records.count
    assert_equal 'Lisa Simpson', request.records.first.name
  end


end