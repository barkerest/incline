require 'test_helper'

class LogTest < ActiveSupport::TestCase

  def setup
    @io = StringIO.new
  end

  test 'output is always set' do
    assert Incline::Log::get_output
  end

  test 'output can be changed' do
    begin
      Incline::Log::set_output @io
      assert_equal @io, Incline::Log::get_output

      Incline::Log::debug   'This is a debug message.'
      Incline::Log::info    'This is an informative message.'
      Incline::Log::warn    'This is a warning message.'
      Incline::Log::error   'This is an error message.'

      assert @io.string =~ /DEBUG/
      assert @io.string =~ /INFO/
      assert @io.string =~ /WARN/
      assert @io.string =~ /ERROR/

    ensure
      Incline::Log::set_output false
    end
    assert_not_equal @io, Incline::Log::get_output
    Incline::Log::info 'If you see this, everything is OK.'
    assert_not @io.string =~ /everything is OK/
  end

end