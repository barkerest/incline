require 'test_helper'

class DateTimeValueExtensionsTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  def setup
    # Create a test table.
    silence_stream STDOUT do
      ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
        t.datetime :my_value
      end
    end

    # And then create a test model.
    eval <<-EOM
class #{TEST_TABLE_CLASS} < ActiveRecord::Base
  self.table_name = #{TEST_TABLE_NAME.inspect}
end
    EOM

    @backup_ar_tz = ActiveRecord::Base.default_timezone
    @backup_tm_tz = Time.zone.name
    ActiveRecord::Base.default_timezone = :utc
    Time.zone = 'UTC'

    # Store the model class for use.
    @model_class = self.class.const_get TEST_TABLE_CLASS
    @item = @model_class.new
  end

  def teardown
    # Undefine the model class (or at least remove it from the Object namespace).
    self.class.send :remove_const, TEST_TABLE_CLASS

    # Remove the table from the database.
    silence_stream STDOUT do
      ActiveRecord::Migration::drop_table TEST_TABLE_NAME
    end

    ActiveRecord::Base.default_timezone = @backup_ar_tz
    Time.zone = @backup_tm_tz
  end

  test 'accepts valid values' do
    {
        '2016-12-31' => Time.utc(2016,12,31),
        '12/31/2016' => Time.utc(2016,12,31),
        '16-12-31' => Time.utc(2016,12,31),
        '12/31/16' => Time.utc(2016,12,31),
        '2016-12-31 1:20' => Time.utc(2016,12,31,1,20),
        '12/31/2016 1:20' => Time.utc(2016,12,31,1,20),
        '12/31/2016 1:20 PM' => Time.utc(2016,12,31,13,20),
        '12/31/2016 12:20 AM' => Time.utc(2016,12,31,0,20),
        '12/31/2016 12:20 PM' => Time.utc(2016,12,31,12,20),
        '12/31/2016 24:00' => Time.utc(2017,1,1,0,0),
        '2016-12-31T24:00' => Time.utc(2017,1,1,0,0),
        '2016-12-31 24:00-01:00' => Time.utc(2016,12,31,23,0),
    }.each do |s,v|
      @item.my_value = s
      assert_equal v, @item.my_value, "Should have accepted #{s.inspect}"
    end

  end

  test 'rejects invalid values' do

    [
        '',
        '  ',
        '0000-00-00',
        '0000-00-00 00:00:00',
        '2016-13-31',
        '2016-12-32',
        '2016-02-30',
        '2/30/2016',
        '1/1/2017 24:01',
        '12:30'
    ].each do |val|
      @item.my_value = val
      assert_nil @item.my_value, "Should have rejected #{val.inspect}"
    end

  end

end