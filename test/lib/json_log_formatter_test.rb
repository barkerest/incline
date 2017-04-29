require 'test_helper'
require 'json'
require 'ansi/code'

class JsonLogFormatterTest < ActiveSupport::TestCase

  def setup
    @fmt = Incline::JsonLogFormatter.new
  end

  test 'should create valid JSON' do
    t = Time.now
    s = @fmt.call(Logger::WARN, t, :ignored, 'Something happened!')
    assert_not s.blank?

    # ends with CRLF?
    assert s =~ /\r\n\Z/

    h = JSON.parse(s.strip) rescue nil
    assert h.is_a?(Hash)
    assert_equal 'WARN',                          h['level']
    assert_equal t.strftime('%Y-%m-%d %H:%M:%S'), h['time']
    assert_equal 'Something happened!',           h['message']
    assert_equal Rails.application.app_name,      h['app_name']
    assert_equal Rails.application.app_version,   h['app_version']
    assert_equal Process.pid,                     h['process_id']
  end

  test 'should log all CRLF as LF' do
    h = JSON.parse(@fmt.call(Logger::INFO, Time.now, :ignored, "This message has \r\n CRLF \r\n sequences in it!\r\n").strip)
    assert_not h['message'] =~ /\r\n/
    assert h['message'] =~ /\n/
  end

  test 'should strip out ANSI formatting' do
    test = 'This text has ' + ANSI.ansi('red', :bright, :red) + ' and ' + ANSI.ansi('green', :green) + ' text.'
    clean = 'This text has red and green text.'
    assert_not_equal clean, test
    h = JSON.parse(@fmt.call(Logger::INFO, Time.now, :ignored, test))
    assert_equal clean, h['message']
  end

end