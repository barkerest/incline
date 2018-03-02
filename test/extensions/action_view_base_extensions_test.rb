require 'test_helper'
require 'cgi/util'

class ActionViewBaseExtensionsTest < ActiveSupport::TestCase

  class TestModel
    def errors
      @errors ||= TestErrors.new
    end
  end

  class TestErrors
    def any?
      true
    end
    def count
      10
    end
    def full_messages
      @full_messages ||= (1..10).to_a.map{ |v| "This is error ##{v}." }
    end
  end


  def setup
    @view = ActionView::Base.new
  end

  test 'should have extension methods' do
    assert @view.respond_to?(:full_title)
    assert @view.respond_to?(:show_check_if)
    assert @view.respond_to?(:glyph)
    assert @view.respond_to?(:render_alert)
    assert @view.respond_to?(:error_summary)
    assert @view.respond_to?(:fmt_date)
    assert @view.respond_to?(:fmt_num)
    assert @view.respond_to?(:gravatar_for)
    assert @view.respond_to?(:panel)
  end

  test 'full_title should work as expected' do
    app_name = Rails.application.app_name.strip
    assert_equal app_name, @view.full_title
    assert_equal "Hello World | #{app_name}", @view.full_title('Hello World')
  end

  test 'show_check_if should work as expected' do
    # false should be nil.
    assert_nil @view.show_check_if(false)
    assert_nil @view.show_check_if(nil)

    # true should not be nil.
    expected = '<i class="glyphicon glyphicon-ok glyphicon-small"></i>'
    val = @view.show_check_if(true)
    assert_not val.blank?
    assert_equal expected, val
    assert val.html_safe?

    # values that convert to true should also work.
    assert_equal val, @view.show_check_if(:true)
    assert_equal val, @view.show_check_if('true')
    assert_equal val, @view.show_check_if('yes')
    assert_equal val, @view.show_check_if('1')
    assert_equal val, @view.show_check_if(1)

    # and those that convert to false should be nil
    assert_nil @view.show_check_if(:false)
    assert_nil @view.show_check_if('false')
    assert_nil @view.show_check_if('no')
    assert_nil @view.show_check_if('0')
    assert_nil @view.show_check_if(0)
  end

  test 'glyph should work as expected' do
    # blank values should return nil.
    assert_nil @view.glyph(nil)
    assert_nil @view.glyph('')
    assert_nil @view.glyph('   ')

    expected = '<i class="glyphicon glyphicon-ok"></i>'
    assert_equal expected, @view.glyph(:ok)
    assert_equal expected, @view.glyph('ok')
    assert_equal expected, @view.glyph(' ok ')
    assert_equal expected, @view.glyph(:ok, :normal)  # invalid size
    assert_equal expected, @view.glyph(:ok, :big)     # invalid size
    assert_equal expected, @view.glyph(:ok, :tiny)    # invalid size

    expected = '<i class="glyphicon glyphicon-cloud glyphicon-small"></i>'
    assert_equal expected, @view.glyph(:cloud, :small)
    assert_equal expected, @view.glyph('cloud', 'small')
    assert_equal expected, @view.glyph(:cloud, 'sm')
    assert_equal expected, @view.glyph('cloud', :sm)

    expected = '<i class="glyphicon glyphicon-remove glyphicon-large"></i>'
    assert_equal expected, @view.glyph(:remove, :large)
    assert_equal expected, @view.glyph(:remove, 'lg')
  end

  test 'fmt_date should work as expected' do
    assert_nil @view.fmt_date(nil)
    assert_nil @view.fmt_date('')
    assert_nil @view.fmt_date('  ')

    # test the string formats.
    assert_equal '1/1/2017', @view.fmt_date('1/1/2017')
    assert_equal '12/31/2017', @view.fmt_date('12/31/2017')
    assert_equal '1/1/2017', @view.fmt_date('2017-01-01')
    assert_equal '12/31/2017', @view.fmt_date('2017-12-31')
    assert_equal '1/1/2017', @view.fmt_date('2017-1-1 12:30 PM')
    assert_equal '12/31/2017', @view.fmt_date('12/31/2017 12:30 PM')

    val = Time.parse('2016-05-08')
    assert_equal '5/8/2016', @view.fmt_date(val)

    val = Date.new(2016,12,31)
    assert_equal '12/31/2016', @view.fmt_date(val)

    val = Time.parse('2016-12-31 23:00:00 -04:00')
    assert_equal '12/31/2016', @view.fmt_date(val)
    assert_equal '1/1/2017', @view.fmt_date(val.utc)
  end

  test 'fmt_num should work as expected' do
    assert_nil @view.fmt_num(nil)
    assert_nil @view.fmt_num('')
    assert_nil @view.fmt_num('  ')

    assert_equal '0.00', @view.fmt_num(0)
    assert_equal '0.00', @view.fmt_num('0')

    assert_equal '1.50', @view.fmt_num(1.499997)
    assert_equal '123.45', @view.fmt_num('123.450678')

    assert_equal '150', @view.fmt_num(150, 0)
    assert_equal '123', @view.fmt_num(123.456, 0)

    assert_equal '1.0000', @view.fmt_num(1, 4)
    assert_equal '123.4567', @view.fmt_num(123.4567, 4)
  end

  test 'render_alert accepts valid alert types' do
    {
        :success => :success,
        :info => :info,
        :warning => :warning,
        :danger => :danger,
        :notice => :info,
        :alert => :danger,
        :error => :danger,
        :warn => :warning,
        :safe_success => :success,
        :safe_info => :info,
        :safe_warning => :warning,
        :safe_danger => :danger,
        :safe_notice => :info,
        :safe_alert => :danger,
        :safe_error => :danger,
        :safe_warn => :warning
    }.each do |type, klass|
      expected = "<div class=\"alert alert-#{klass} alert-dismissible\">" +
          '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
          '<span>Hello World</span>' +
          '</div>'
      assert_equal expected, @view.render_alert(type, 'Hello World'), "Mismatch for #{type.inspect}"
    end
  end

  test 'render_alert converts invalid alert types to info' do
    [
        :good, :not_good, :fatal, :information, :xyz
    ].each do |type|
      expected = '<div class="alert alert-info alert-dismissible">' +
          '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
          '<span>Hello World</span>' +
          '</div>'
      assert_equal expected, @view.render_alert(type, 'Hello World')
    end
  end

  test 'render_alert supports simple markdown' do
    expected = '<div class="alert alert-info alert-dismissible">' +
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
        '<span><strong>Hello</strong> World</span>' +
        '</div>'
    assert_equal expected, @view.render_alert(:info, '__Hello__ World')
  end

  test 'render_alert handles arrays correctly' do
    expected = '<div class="alert alert-info alert-dismissible">' +
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
        '<span>Line 1</span><br>' +
        '<span>Line 2</span>' +
        '</div>'
    assert_equal expected, @view.render_alert(:info, [ 'Line 1', 'Line 2' ])
  end

  test 'render_alert handles hashes correctly' do
    expected = '<div class="alert alert-danger alert-dismissible">' +
            '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
            '<div>Name<ul><li>cannot be blank</li><li>must be unique</li></ul></div>' +
            '<div>Age<ul><li>must be greater than 18</li></ul></div>' +
            '</div>'
    assert_equal expected, @view.render_alert(:error, { :name => [ 'cannot be blank', 'must be unique' ], :age => 'must be greater than 18' })
  end

  test 'render_alert handles mixed message correctly' do
    expected = '<div class="alert alert-danger alert-dismissible">' +
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
        '<span><strong>The model could not be saved.</strong></span><br>' +
        '<div>Name<ul><li>cannot be blank</li><li>must be unique</li></ul></div>' +
        '<div>Age<ul><li>must be greater than 18</li></ul></div>' +
        '</div>'
    assert_equal expected, @view.render_alert(:error, [ '__The model could not be saved.__', { :name => [ 'cannot be blank', 'must be unique' ], :age => 'must be greater than 18' } ])
  end

  test 'render_alert safe vs unsafe test' do

    text = 'This is <em>my</em> test value &#9786;<br>There is <strong>nothing</strong> you can do about it.'
    safe_text = CGI::escape_html(text)

    expected = '<div class="alert alert-info alert-dismissible">' +
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
        "<span>#{safe_text}</span>" +
        '</div>'
    assert_equal expected, @view.render_alert(:info, text)

    expected = '<div class="alert alert-info alert-dismissible">' +
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
        "<span>#{text}</span>" +
        '</div>'
    assert_equal expected, @view.render_alert(:safe_info, text)
  end

  test 'error_summary should work as expected' do
    expected = "<div id=\"error_explanation\"><div class=\"alert alert-danger\">" +
        "<div><strong>The form contains 10 errors.</strong><ul>" +
        "<li>This is error #1.</li><li>This is error #2.</li><li>This is error #3.</li><li>This is error #4.</li>" +
        "<li>This is error #5.</li>" +
        "<li class=\"alert_52444_show\"><a href=\"javascript:show_alert_52444()\" title=\"Show 5 more\">... plus 5 more</a></li>" +
        "<li class=\"alert_52444\" style=\"display: none;\">This is error #6.</li>" +
        "<li class=\"alert_52444\" style=\"display: none;\">This is error #7.</li>" +
        "<li class=\"alert_52444\" style=\"display: none;\">This is error #8.</li>" +
        "<li class=\"alert_52444\" style=\"display: none;\">This is error #9.</li>" +
        "<li class=\"alert_52444\" style=\"display: none;\">This is error #10.</li>" +
        "</ul></div>" +
        "<script type=\"text/javascript\">\n//<![CDATA[\nfunction show_alert_52444() { $('.alert_52444_show').hide(); $('.alert_52444').show(); }\n\n//]]>\n</script>\n" +
        "</div></div>"

    val = @view.error_summary(TestModel.new)

    assert val
    assert val =~ /show_alert_([0-9a-fA-F]{5})\(\)/
    id = $1
    expected = expected.gsub('52444', id)

    assert_equal expected, val
  end

  test 'gravatar_for should work as expected' do
    # TODO: Fill in test.
  end

  test 'panel should work as expected' do
    # TODO: Fill in test.
  end

end