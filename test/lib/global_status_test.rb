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



end