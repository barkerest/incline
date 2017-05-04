require 'test_helper'

class DecimalValueExtensionsTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  def setup
    # Create a test table.
    silence_stream STDOUT do
      ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
        t.decimal :scaled_value, precision: 12, scale: 4
        t.decimal :unscaled_value, precision: 12
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
    @item = @model_class.new
  end

  def teardown
    # Undefine the model class (or at least remove it from the Object namespace).
    self.class.send :remove_const, TEST_TABLE_CLASS

    # Remove the table from the database.
    silence_stream STDOUT do
      ActiveRecord::Migration::drop_table TEST_TABLE_NAME
    end
  end

  test 'accepts valid values' do
    {
        '1234'        => BigDecimal(1234, 12),
        '1,234'       => BigDecimal(1234, 12),
        '12.34'       => BigDecimal(12.34, 12),
        '1,234.5678'  => BigDecimal(1234.5678, 12),
        '1234567'     => BigDecimal(1234567.0, 12),
        '1,234,567'   => BigDecimal(1234567.0, 12),
        '0'           => BigDecimal(0.0, 12),
        '0.0'         => BigDecimal(0.0, 12),
        '+125'        => BigDecimal(125.0, 12),
        '-125'        => BigDecimal(-125.0, 12),
        '+1,234'      => BigDecimal(1234.0, 12),
        '-1,234'      => BigDecimal(-1234.0, 12)
    }.each do |s,v|
      @item.scaled_value = s
      assert_equal v.round(4), @item.scaled_value, "#{s.inspect} did not parse to #{v}"
      @item.unscaled_value = s
      assert_equal v.to_i, @item.unscaled_value, "#{s.inspect} did not parse to #{v}"
    end
    [ 0, 1234, 567.89 ].each do |v|
      @item.scaled_value = v
      assert_equal BigDecimal(v, 6).round(4), @item.scaled_value
      @item.unscaled_value = v
      assert_equal v.to_i, @item.unscaled_value
    end
  end

  test 'rejects invalid values' do
    [
        '',
        '1,2,3,4',
        ',234',
        '1,2345',
        '0,001',
    ].each do |v|
      @item.scaled_value = v
      assert_nil @item.scaled_value
      @item.unscaled_value = v
      assert_nil @item.unscaled_value
    end
  end




end