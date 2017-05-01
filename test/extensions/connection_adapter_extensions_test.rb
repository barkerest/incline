require 'test_helper'

class ConnectionAdapterExtensionsTest < ActiveSupport::TestCase

  TEST_OBJECT_NAME = "test_object_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4, '0')}"

  def setup
    @conn = ActiveRecord::Base::connection
  end

  test 'should have extension methods' do
    assert @conn.respond_to?(:object_exists?)
    assert @conn.respond_to?(:exec_sp)
  end

  test 'should be able to determine existence' do
    assert_not @conn.object_exists?(TEST_OBJECT_NAME)
    @conn.execute "CREATE TABLE #{TEST_OBJECT_NAME} ( some_value INTEGER NOT NULL )"
    begin
      assert @conn.object_exists?(TEST_OBJECT_NAME)
    ensure
      @conn.execute "DROP TABLE #{TEST_OBJECT_NAME}"
    end
  end

  test 'should be able to execute a stored proc' do
    skip if MsSqlTestConn.skip_tests?
    @conn = MsSqlTestConn.connection

    assert_not @conn.object_exists?(TEST_OBJECT_NAME)

    @conn.execute <<-EOS
CREATE PROCEDURE #{TEST_OBJECT_NAME}
  @i_val INTEGER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @d_val INTEGER;
  SELECT @d_val = ISNULL(@i_val, 0) + 55;
  RETURN @d_val;
END
    EOS
    begin
      # It should exist now.
      assert @conn.object_exists?(TEST_OBJECT_NAME)
      # And it should retrieve the return value.
      assert_equal 55, @conn.exec_sp("exec #{TEST_OBJECT_NAME} NULL")
      assert_equal 100, @conn.exec_sp("exec #{TEST_OBJECT_NAME} 45")
    ensure
      @conn.execute "DROP PROCEDURE #{TEST_OBJECT_NAME}"
    end
  end

end