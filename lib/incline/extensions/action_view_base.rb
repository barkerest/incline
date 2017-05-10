require 'cgi/util'
silence_warnings do
  require 'redcarpet'
end


module Incline::Extensions

  ##
  # Add some extra functionality to the base view definition.
  module ActionViewBase

    ##
    # Gets the full title of the page.
    #
    # If +page_title+ is left blank, then the +app_name+ attribute of your application is returned.
    # Otherwise the +app_name+ attribute is appended to the +page_title+ after a pipe symbol.
    #
    #     # app_name = 'My App'
    #     full_title              # 'My App'
    #     full_title 'Welcome'    # 'Welcome | My App'
    #
    def full_title(page_title = '')
      aname = Rails.application.app_name.strip
      return aname if page_title.blank?
      "#{page_title.strip} | #{aname}"
    end

    ##
    # Shows a small check glyph if the +bool_val+ is true.
    #
    # This is most useful when displaying information in tables..
    # It makes it much easier to quickly include a visual indication of a true value,
    # while leaving the view blank for a false value.
    #
    def show_check_if(bool_val)
      if bool_val.to_bool
        '<i class="glyphicon glyphicon-ok glyphicon-small"></i>'.html_safe
      end
    end

    ##
    # Shows a glyph with an optional size.
    #
    # The glyph +name+ should be a valid {bootstrap glyph}[http://getbootstrap.com/components/#glyphicons] name.
    # Strip the prefixed 'glyphicon-' from the name.
    #
    # The size can be left blank, or set to 'small' or 'large'.
    #
    #   glyph('cloud')    # '<i class="glyphicon glyphicon-cloud"></i>'
    #
    def glyph(name, size = '')
      size =
          case size.to_s.downcase
            when 'small', 'sm'
              'glyphicon-small'
            when 'large', 'lg'
              'glyphicon-large'
            else
              nil
          end

      name = name.to_s.strip
      return nil if name.blank?

      result = '<i class="glyphicon glyphicon-' + CGI::escape_html(name)
      result += ' ' + size unless size.blank?
      result += '"></i>'
      result.html_safe
    end

    ##
    # Renders a dismissible alert message.
    #
    # The +type+ can be :info, :notice, :success, :danger, :alert, or :warning.
    # Optionally, you can prefix the +type+ with 'safe_'.
    # This tells the system that the message you are passing is HTML safe and does not need to be escaped.
    # If you want to include HTML (ie - <br>) in your message, you need to ensure it is actually safe and
    # set the type as :safe_info, :safe_notice, :safe_success, :safe_danger, :safe_alert, or :safe_warning.
    #
    # The +message+ is the data you want to display.
    # * Safe messages must be String values.  No processing is done on safe messages.
    # * Unsafe messages can be a Symbol, a String, an Array, or a Hash.
    #   * An array can contain Symbols, Strings, Arrays, or Hashes.
    #     * Each subitem is processed individually.
    #     * Arrays within arrays are essentially flattened into one array.
    #   * A Hash is converted into an unordered list.
    #     * The keys should be either Symbols or Strings.
    #     * The values can be Symbols, Strings, Arrays, or Hashes.
    #   * A Symbol will be converted into a string, humanized, and capitalized.
    #   * A String will be escaped for HTML, rendered for Markdown, and then returned.
    #     * The Markdown will allow you to customize simple strings by adding some basic formatting.
    #
    # Finally, there is one more parameter, +array_auto_hide+, that can be used to tidy up otherwise
    # long alert dialogs.  If set to a positive integer, this is the maximum number of items to show initially from any
    # array. When items get hidden, a link is provided to show all items.
    # This is particularly useful when you have a long list of errors to show to a user, they will then be able
    # to show all of the errors if they desire.
    #
    #     # render_alert :info, 'Hello World'
    #     <div class="alert alert-info alert-dismissible">
    #       <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    #       <span>Hello World</span>
    #     </div>
    #
    #     # render_alert :success, [ 'Item 1 was successful.', 'Item 2 was successful' ]
    #     <div class="alert alert-info alert-dismissible">
    #       <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    #       <span>Item 1 was successful.</span><br>
    #       <span>Item 2 was successful.</span>
    #     </div>
    #
    #     # render_alert :error, { :name => [ 'cannot be blank', 'must be unique' ], :age => 'must be greater than 18' }
    #     <div class="alert alert-info alert-dismissible">
    #       <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    #       <div>
    #         Name
    #         <ul>
    #           <li>cannot be blank</li>
    #           <li>must be unique</li>
    #         </ul>
    #       </div>
    #       <div>
    #         Age
    #         <ul>
    #           <li>must be greater than 18</li>
    #         </ul>
    #       </div>
    #     </div>
    #
    #     # render_alert :error, [ '__The model could not be saved.__', { :name => [ 'cannot be blank', 'must be unique' ], :age => 'must be greater than 18' } ]
    #     <div class="alert alert-info alert-dismissible">
    #       <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    #       <span><strong>The model could not be saved.</strong></span><br>
    #       <div>
    #         Name
    #         <ul>
    #           <li>cannot be blank</li>
    #           <li>must be unique</li>
    #         </ul>
    #       </div>
    #       <div>
    #         Age
    #         <ul>
    #           <li>must be greater than 18</li>
    #         </ul>
    #       </div>
    #     </div>
    #
    def render_alert(type, message, array_auto_hide = nil)
      return nil if message.blank?

      if type.to_s =~ /\Asafe_/
        type = type.to_s[5..-1]
        message = message.to_s.html_safe
      end

      type = type.to_sym

      type = :info if type == :notice
      type = :danger if type == :alert
      type = :danger if type == :error
      type = :warning if type == :warn

      type = :info unless [:info, :success, :danger, :warning].include?(type)

      array_auto_hide = nil unless array_auto_hide.is_a?(Integer) && array_auto_hide > 0

      contents = render_alert_message(message, array_auto_hide)

      html =
      "<div class=\"alert alert-#{type} alert-dismissible\">" +
          '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' +
          contents[:text]

      unless contents[:script].blank?
        html += <<-EOS
<script type="text/javascript">
<![CDATA[
#{contents[:script]}
]]>
</script>
        EOS
      end

      html += '</div>'

      html.html_safe
    end

    ##
    # Renders the error summary for the specified model.
    def error_summary(model)
      return nil unless model&.respond_to?(:errors)
      return nil unless model.errors&.any?
      contents = render_alert_message(
          {
              "__The form contains #{model.errors.count} error#{model.errors.count == 1 ? '' : 's'}.__" => model.errors.full_messages
          },
          5
      )

      html = '<div id="error_explanation"><div class="alert alert-danger">' + contents[:text]

      unless contents[:script].blank?
        html += <<-EOS
<script type="text/javascript">
<![CDATA[
#{contents[:script]}
]]>
</script>
        EOS
      end

      html += '</div></div>'

      html.html_safe
    end


    ##
    # Formats a date in US format (M/D/YYYY).
    #
    # The +date+ can be a string in the correct format, or a Date/Time object.
    # If the +date+ is blank, then nil will be returned.
    def fmt_date(date)
      return nil if date.blank?
      # We want our date in a string format, so only convert to time if we aren't in a string, time, or date.
      if date.respond_to?(:to_time) && !date.is_a?(::String) && !date.is_a?(::Time) && !date.is_a?(::Date)
        date = date.to_time
      end
      # Now if we have a Date or Time value, convert to string.
      if date.respond_to?(:strftime)
        date = date.strftime('%m/%d/%Y')
      end
      return nil unless date.is_a?(::String)

      # Now the string has to match one of our expected formats.
      if date =~ Incline::DateTimeFormats::ALMOST_ISO_DATE_FORMAT
        m,d,y = [ $2, $3, $1 ].map{|v| v.to_i}
        "#{m}/#{d}/#{y.to_s.rjust(4,'0')}"
      elsif date =~ Incline::DateTimeFormats::US_DATE_FORMAT
        m,d,y = [ $1, $2, $3 ].map{|v| v.to_i}
        "#{m}/#{d}/#{y.to_s.rjust(4,'0')}"
      else
        nil
      end
    end

    ##
    # Formats a number with the specified number of decimal places.
    #
    # The +value+ can be any valid numeric expression that can be converted into a float.
    def fmt_num(value, places = 2)
      return nil if value.blank?

      value =
          if value.respond_to?(:to_f)
            value.to_f
          else
            nil
          end

      return nil unless value.is_a?(::Float)

      "%0.#{places}f" % value.round(places)
    end


    private

    def redcarpet
      @redcarpet ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(no_intra_emphasis: true, fenced_code_blocks: true, strikethrough: true, autolink: true))
    end

    def render_md(text)
      text = redcarpet.render(text)
      # Use /Z to match before a trailing newline.
      if /\A<p>(.*)<\/p>\Z/i =~ text
        $1
      else
        text
      end
    end

    def render_alert_message(message, array_auto_hide, bottom = true, state = nil)
      state ||= { text: '', script: '' }

      if message.is_a?(Array)

        # flatten the array, then map to the text values.
        message = message.flatten
                      .map { |v| render_alert_message(v, array_auto_hide, bottom, nil) }
                      .map do |v|
          state[:script] += v[:script]
          v[:text]
        end

        if array_auto_hide && message.count > array_auto_hide && array_auto_hide > 0
          # We want to hide some records.

          # Generate a random ID for these items.
          id = 'alert_' + SecureRandom.random_number(1<<20).to_s(16).rjust(5,'0')

          init_count = array_auto_hide
          remaining = message.count - init_count

          # Rebuild the array by inserting the link after the initial records.
          # The link gets a class of 'alert_#####_show' and the items following it get a class of 'alert_#####'.
          # The items following also get a 'display: none;' style to hide them.
          message = message[0...init_count] +
              [
                  (bottom ? '<span' : '<li') + " class=\"#{id}_show\">" +
                      "<a href=\"javascript:show_#{id}()\" title=\"Show #{remaining} more\">... plus #{remaining} more</a>" +
                      (bottom ? '</span>' : '</li>')
              ] +
              message[init_count..-1].map{|v| v.gsub(/\A<(li|span|div)>/, "<\\1 class=\"#{id}\" style=\"display: none;\">") }

          state[:text] += message.join(bottom ? '<br>' : '')

          # When the link gets clicked, hide the link and show the hidden items.
          state[:script] += "function show_#{id}() { $('.#{id}_show').hide(); $('.#{id}').show(); }\n"
        else
          state[:text] += message.join(bottom ? '<br>' : '')
        end

      elsif message.is_a?(Hash)
        # Process each item as <li>::KEY::<ul>::VALUES::</ul></li>
        message.each do |k,v|
          state[:text] += bottom ? '<div>' : '<li>'
          if k.is_a?(Symbol)
            state[:text] += CGI::escape_html(k.to_s.humanize.capitalize)
          elsif k.is_a?(String)
            state[:text] += render_md(CGI::escape_html(k))
          else
            state[:text] += CGI::escape_html(k.inspect)
          end
          unless v.blank?
            state[:text] += '<ul>'
            render_alert_message v, array_auto_hide, false, state
            state[:text] += '</ul>'
          end
          state[:text] += bottom ? '</div>' : '</li>'
        end
      else
        # Make the text safe.
        # If the message is an HTML safe string, don't process it.
        text =
            if message.html_safe?
              message
            else
              render_md(CGI::escape_html(message.to_s))
            end

        if bottom
          state[:text] += "<span>#{text}</span>"
        else
          state[:text] += "<li>#{text}</li>"
        end
      end
      state
    end


  end

end

ActionView::Base.include Incline::Extensions::ActionViewBase
