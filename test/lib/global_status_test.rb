require 'test_helper'

class GlobalStatusTest < ActiveSupport::TestCase

  def setup
    @stat = Incline::GlobalStatus.new
  end

  test 'should allow locking' do
    begin
      assert @stat.acquire_lock
      assert @stat.is_locked?
      assert @stat.have_lock?
      assert Incline::GlobalStatus::locked?
    ensure
      @stat.release_lock
    end
    assert_not @stat.is_locked?
    assert_not @stat.have_lock?
    assert_not Incline::GlobalStatus::locked?
  end

  test 'should allow blocks' do
    # block is successful, but @stat cannot acquire a lock.
    Incline::GlobalStatus::lock_for do |stat|
      assert stat
      assert stat.is_locked?
      assert stat.have_lock?
      assert @stat.is_locked?
      assert_not @stat.have_lock?
      assert_not @stat.acquire_lock
    end
    assert_not @stat.is_locked?

    # @stat is successful, but block cannot acquire a lock.
    begin
      assert @stat.acquire_lock
      assert @stat.is_locked?
      assert @stat.have_lock?
      assert Incline::GlobalStatus::locked?
      Incline::GlobalStatus::lock_for do |stat|
        assert_not stat
      end
    ensure
      @stat.release_lock
    end
  end

  test 'should be able to set status' do
    Incline::GlobalStatus::lock_for do |stat|
      assert stat

      # We haven't set a status, so the default messages should be in place.
      # There should be no percentage yet either.
      data = stat.get_status
      assert data.is_a?(Hash)
      assert data[:locked]
      assert_equal 'The current process is busy.', data[:message]
      assert data[:percent].blank?

      # The helpers should match.
      assert_equal data[:message], stat.get_message
      assert_nil stat.get_percentage

      # The message should be slightly different, but otherwise the data is the same.
      data = Incline::GlobalStatus::current
      assert data.is_a?(Hash)
      assert data[:locked]
      assert_equal 'The system is busy.', data[:message]
      assert data[:percent].blank?

      # Set the message.
      stat.set_status 'Doing something.', 25

      # The new status should be set correctly.
      data = stat.get_status
      assert_equal 'Doing something.', data[:message]
      assert_equal '25', data[:percent]
      assert_equal data[:message], stat.get_message
      assert_equal 25, stat.get_percentage

      # And this should be the same.
      data = Incline::GlobalStatus::current
      assert_equal 'Doing something.', data[:message]
      assert_equal '25', data[:percent]
    end
  end

end