require 'test_helper'

class DateTimeFormatsTest < ActiveSupport::TestCase

  test 'should process valid US dates' do
    {
        '12/31/2016' => { year: 2016, month: 12, day: 31 },
        '12/31/2016 11:35' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35 },
        '12/31/2016 11:35:48' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48 },
        '12/31/2016 11:35:48.1024' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024 },
        '12/31/2016 11:35:48.1024 PM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, ampm: 'P' },
        '12/31/2016 11:35:48.1024 AM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, ampm: 'A' },
        '12/31/2016 11:35:48.0001' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: '0001' },
        '1/1/2017 1:15' => { year: 2017, month: 1, day: 1, hour: 1, minute: 15 },
        '01/01/2017 01:15' => { year: 2017, month: '01', day: '01', hour: '01', minute: 15 },
        '1/1/16' => { year: 16, month: 1, day: 1 },
        '12/31/2016 11:35PM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
        '12/31/2016 11:35P' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
        '12/31/2016 11:35 PM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
        '12/31/2016 11:35 P' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
    }.each do |dt, parts|
      match = Incline::DateTimeFormats::US_DATE_FORMAT.match(dt)
      assert match, "Should match '#{dt}'."
      parts.each do |k,v|
        assert_equal v.to_s, match[k.to_s.upcase], "Part #{k} does not equal '#{v}' for '#{dt}'."
      end
    end
  end

  test 'should reject invalid US dates' do
    [
        '12.31.2016',
        '12-31-2016',
        '12/31/2016 1550',
        '12/31/201612:25',
        '12/31/2016 AM',
        '12/31/2016 12 PM',
        '12/31/2016 12P'
    ].each do |dt|
      assert_nil Incline::DateTimeFormats::US_DATE_FORMAT.match(dt), "Should not match '#{dt}'."
    end
  end

  test 'should process valid ISO-ish dates' do
    {
        '2016-12-31' => { year: 2016, month: 12, day: 31 },
        '2016-12-31 11:35' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35 },
        '2016-12-31 11:35:48' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48 },
        '2016-12-31 11:35:48.1024' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024 },
        '2016-12-31 11:35:48.0001' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: '0001' },
        '2016-12-31 11:35:48.1024 -05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00' },
        '2016-12-31 11:35:48.1024-05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00' },
        '2016-12-31 11:35:48.1024 -0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-0500' },
        '2016-12-31 11:35:48.1024-0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-0500' },
        '2016-12-31 11:35:48.1024 +05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+05:00' },
        '2016-12-31 11:35:48.1024+05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+05:00' },
        '2016-12-31 11:35:48.1024 +0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+0500' },
        '2016-12-31 11:35:48.1024+0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+0500' },
        '2016-12-31 11:35:48.1024Z' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: 'Z' },
        '2016-12-31 11:35:48.1024 Z' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: 'Z' },
        '2017-1-1 1:15' => { year: 2017, month: 1, day: 1, hour: 1, minute: 15 },
        '2017-01-01 01:15' => { year: 2017, month: '01', day: '01', hour: '01', minute: 15 },
        '2016-12-31T11:35' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35 },
        '2016-12-31T11:35:48' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48 },
        '2016-12-31T11:35:48.1024' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024 },
        '2016-12-31T11:35:48.1024 -05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00' },
        '2016-12-31T11:35:48.1024-05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00' },
        '2016-12-31T11:35:48.1024 -0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-0500' },
        '2016-12-31T11:35:48.1024-0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-0500' },
        '2016-12-31T11:35:48.1024 +05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+05:00' },
        '2016-12-31T11:35:48.1024+05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+05:00' },
        '2016-12-31T11:35:48.1024 +0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+0500' },
        '2016-12-31T11:35:48.1024+0500' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '+0500' },
        '2016-12-31T11:35:48.1024Z' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: 'Z' },
        '2016-12-31T11:35:48.1024 Z' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: 'Z' },
        '2016-12-31T11:35:48.0001' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: '0001' },
        '2017-1-1T1:15' => { year: 2017, month: 1, day: 1, hour: 1, minute: 15 },
        '2017-01-01T01:15' => { year: 2017, month: '01', day: '01', hour: '01', minute: 15 },
        '16-1-1' => { year: 16, month: 1, day: 1 },
        '2016-12-31 11:35 PM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
        '2016-12-31 11:35:48 PM' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, ampm: 'P' },
        '2016-12-31 11:35P' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, ampm: 'P' },
        '2016-12-31 11:35:48P' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, ampm: 'P' },
        '2016-12-31 11:35:48.1024 PM -05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00', ampm: 'P' },
        '2016-12-31 11:35:48.1024P-05:00' => { year: 2016, month: 12, day: 31, hour: 11, minute: 35, second: 48, fraction: 1024, tz: '-05:00', ampm: 'P' },
    }.each do |dt, parts|
      match = Incline::DateTimeFormats::ALMOST_ISO_DATE_FORMAT.match(dt)
      assert match, "Should match '#{dt}'."
      parts.each do |k,v|
        assert_equal v.to_s, match[k.to_s.upcase], "Part #{k} does not equal '#{v}' for '#{dt}'."
      end
    end
  end

  test 'should reject invalid ISO-ish dates' do
    [
        '2016.12.31',
        '2016/12/31',
        '2016-12-31 1550',
        '2016-12-3112:25',
        '2016-12-31 -05:00',
        '2016-12-31-05:00',
        '2016-12-31 11:45:00 05:00',
        '2016-12-31Z',
        '2016-12-31 Z'
    ].each do |dt|
      assert_nil Incline::DateTimeFormats::ALMOST_ISO_DATE_FORMAT.match(dt), "Should not match '#{dt}'."
    end
  end

end