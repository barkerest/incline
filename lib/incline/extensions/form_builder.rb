

module Incline::Extensions
  ##
  # Adds additional helper methods to form builders.
  module FormBuilder

    ##
    # Creates a date picker selection field using a bootstrap input group.
    #
    # *Valid options:*
    #
    # input_group_size::
    #     Valid optional sizes are 'small' or 'large'.
    # readonly::
    #     Set to true to make the input field read only.
    # pre_calendar::
    #     Set to true to put a calendar icon before the input field.
    # post_calendar::
    #     Set to true to put a calendar icon after the input field.  This is the default setting if no other pre/post
    #     is selected.
    # pre_label::
    #     Set to a text value to put a label before the input field.  Replaces +pre_calendar+ if specified.
    # post_label::
    #     Set to a text value to put a label after the input field.  Replaces +post_calendar+ if specified.
    #
    #   f.date_picker :end_date, :pre_label => 'End'
    #
    def date_picker(method, options = {})
      options = {
          class:            'form-control',
          read_only:        false,
          pre_calendar:     false,
          pre_label:        nil,
          post_calendar:    false,
          post_label:       false,
          attrib_val:       { },
          style:            { },
          input_group_size: ''
      }.merge(options)

      style = ''
      options[:style].each { |k,v| style += "#{k}: #{v};" }

      attrib = options[:attrib_val]
      attrib[:class] = options[:class]
      attrib[:style] = style
      attrib[:readonly] = 'readonly' if options[:read_only]

      if %w(sm small input-group-sm).include?(options[:input_group_size])
        options[:input_group_size] = 'input-group-sm'
      elsif %w(lg large input-group-lg).include?(options[:input_group_size])
        options[:input_group_size] = 'input-group-lg'
      else
        options[:input_group_size] = ''
      end

      attrib[:value] = object.send(method).strftime('%m/%d/%Y') if object.send(method)
      fld = text_field(method, attrib)

      # must have at least one attachment, default to post-calendar.
      options[:post_calendar] = true unless options[:pre_calendar] || options[:pre_label] || options[:post_label]

      # labels override calendars.
      options[:pre_calendar] = false if options[:pre_label]
      options[:post_calendar] = false if options[:post_label]

      # construct the prefix
      if options[:pre_calendar]
        pre = '<span class="input-group-addon"><i class="glyphicon glyphicon-calendar"></i></span>'
      elsif options[:pre_label]
        pre = "<span class=\"input-group-addon\">#{h options[:pre_label]}</span>"
      else
        pre = ''
      end

      # construct the postfix
      if options[:post_calendar]
        post = '<span class="input-group-addon"><i class="glyphicon glyphicon-calendar"></i></span>'
      elsif options[:post_label]
        post = "<span class=\"input-group-addon\">#{h options[:post_label]}</span>"
      else
        post = ''
      end

      # and then the return value.
      "<div class=\"input-group date #{options[:input_group_size]}\">#{pre}#{fld}#{post}</div>".html_safe
    end

    ##
    # Creates a multiple input field control for the provided form.
    #
    # The +methods+ parameter can be either an array of method names, or a hash with method names as the
    # keys and labels as the values.
    #
    # For instance:
    #   [ :alpha, :bravo, :charlie ]
    #   { :alpha => 'The first item', :bravo => 'The second item', :charlie => 'The third item' }
    #
    # *Valid options:*
    #
    # class::
    #     The CSS class to apply. Defaults to 'form-control'.
    #
    # read_only::
    #     Should the control be read-only?  Defaults to false.
    #
    # style::
    #     A hash containing CSS styling attributes to apply to the input fields.
    #     Width is generated automatically or specified individually using the "field_n" option.
    #
    # input_group_size::
    #     You can specific *small* or *large* to change the control's overall size.
    #
    # attrib::
    #     Any additional attributes you want to apply to the input fields.
    #
    # field_n::
    #     Sets specific attributes for field "n".  These values will override the "attrib" and "style" options.
    #
    #   f.multi_input [ :city, :state, :zip ],
    #       :field_1 => { :maxlength => 30, :style => { :width => '65%' } },
    #       :field_2 => { :maxlength => 2 },
    #       :field_3 => { :maxlength => 10, :style => { :width => '25%' } }
    #
    def multi_input(methods, options = {})
      raise ArgumentError.new('methods must be either a Hash or an Array') unless methods.is_a?(Hash) || methods.is_a?(Array)
      options = options.dup

      # add some defaults.
      options = {
          class: 'form-control',
          read_only: false,
          attrib: { },
          style: { },
          input_group_size: ''
      }.merge(options)

      # build the style attribute.
      options[:attrib][:style] ||= ''
      options[:style].each do |k,v|
        if k.to_s == 'width'
          options[:input_group_width] = "width: #{v};"
        else
          options[:attrib][:style] += "#{k}: #{v};"
        end
      end

      # Standardize the "methods" list to be an array of arrays.
      if methods.is_a?(Hash)
        methods = methods.to_a
      elsif methods.is_a?(Array)
        methods = methods.map{|v| v.is_a?(Array) ? v : [ v, v.to_s.humanize ] }
      end

      # Extract field attributes.
      fields = { }
      index = 1
      methods.each do |(meth,label)|
        fields[meth] = options[:attrib].merge(options.delete(:"field_#{index}") || {})
        fields[meth][:readonly] = 'readonly' if options[:read_only]
        fields[meth][:class] ||= options[:class]
        if fields[meth][:style].is_a?(Hash)
          fields[meth][:style] = fields[meth][:style].to_a.map{|v| v.map(&:to_s).join(':') + ';'}.join(' ')
        end
        fields[meth][:placeholder] ||= label
      end

     if %w(sm small input-group-sm).include?(options[:input_group_size])
        options[:input_group_size] = 'input-group-sm'
      elsif %w(lg large input-group-lg).include?(options[:input_group_size])
        options[:input_group_size] = 'input-group-lg'
      else
        options[:input_group_size] = ''
      end

      # We want each field to have a width specified.
      remaining_width = 100.0
      remaining_fields = fields.count
      width_match_1 = /^width:([^;]);/
      width_match_2 = /;\s*width:([^;]);/

      # pass 1, compute remaining width.
      fields.each do |meth, attr|
        width = width_match_1.match(attr[:style]) || width_match_2.match(attr[:style])
        if width
          if width[-1] == '%'
            width = width[0...-1].strip.to_f
            if width > remaining_width
              Incline::Log::warn "Field width adds up to more than 100% in multi_input affecting field \"#{meth}\"."
              width = remaining_width
              attr[:style] = attr[:style].gsub(width_match_1, '').gsub(width_match_2, '') + "width: #{width}%;"
            end
            remaining_width -= width
            remaining_width = 0 if remaining_width < 0
            remaining_fields -= 1
          else
            # we do not support pixel, em, etc, so dump the unsupported width.
            Incline::Log::warn "Unsupported width style in multi_input affecting field \"#{meth}\": #{width}"
            attr[:style] = attr[:style].gsub(width_match_1, '').gsub(width_match_2, '')
          end
        end
      end

      # pass 2, fill in missing widths.
      fields.each do |meth, attr|
        width = width_match_1.match(attr[:style]) || width_match_2.match(attr[:style])
        unless width
          width =
            if remaining_fields > 1
              (remaining_width / remaining_fields).to_i
            else
              remaining_width
            end

          Incline::Log::warn "Computed field width of 0% in multi_input affecting field \"#{meth}\"." if width == 0

          attr[:style] += "width: #{width}%;"
          remaining_width -= width
          remaining_fields -= 1
          remaining_width = 0 if remaining_width < 0
        end
      end

      fld = []
      fields.each do |meth, attr|
        attr[:value] = object.send(meth)
        fld << text_field(meth, attr)
      end

      "<div class=\"input-group #{options[:input_group_size]}\" style=\"#{options[:input_group_width]}\">#{fld.join}</div>".html_safe
    end

    ##
    # Creates a currency entry field.
    #
    # *Valid options:*
    #
    # currency_symbol::
    #       A string used to prefix the input field.  Defaults to '$'.
    #
    # All other options will be passed through to the {FormHelper#text_field}[http://apidock.com/rails/ActionView/Helpers/FormHelper/text_field] method.
    #
    # The value will be formatted with comma delimiters and two decimal places.
    #
    #   f.currency :pay_rate
    #
    def currency_field(method, options = {})
      # get the symbol for the field.
      sym = options.delete(:currency_symbol) || '$'

      # get the value
      if (val = object.send(method))
        options[:value] = number_with_precision val, precision: 2, delimiter: ','
      end

      # build the field
      fld = text_field(method, options)

      # return the value.
      "<div class=\"input-symbol\"><span>#{h sym}</span>#{fld}</div>".html_safe
    end

    ##
    # Creates a label followed by an optional small text description.
    #   For instance, <label>Hello</label> <small>(World)</small>
    #
    # Valid options:
    #
    # text::
    #     The text for the label.  If not set, the method name is humanized and that value will be used.
    #
    # small_text::
    #     The small text to follow the label.  If not set, then no small text will be included.
    #     This is useful for flagging fields as optional.
    #
    # For additional options, see {FormHelper#label}[http://apidock.com/rails/ActionView/Helpers/FormHelper/label].
    def label_w_small(method, options = {})
      text = options.delete(:text) || method.to_s.humanize
      small_text = options.delete(:small_text)
      label(method, text, options) +
          (small_text ? " <small>(#{h small_text})</small>" : '').html_safe
    end

    ##
    # Creates a standard form group with a label and text field.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    # For field options, see {FormHelper#text_field}[http://apidock.com/rails/ActionView/Helpers/FormHelper/text_field].
    #
    def text_form_group(method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = label_w_small(method, lopt)
      fld = gopt[:wrap].call(text_field(method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a standard form group with a label and currency field.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    # For field options, see #currency_field.
    #
    def currency_form_group(method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = label_w_small(method, lopt)
      fld = gopt[:wrap].call(currency_field(method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a standard form group with a label and a static text field.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    #
    # Field options:
    #
    # value::
    #   Allows you to specify a value for the static field, otherwise the value from +method+ will be used.
    #
    def static_form_group(method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = label_w_small(method, lopt)
      fld = gopt[:wrap].call("<input type=\"text\" class=\"form-control disabled\" readonly=\"readonly\" value=\"#{h(fopt[:value] || object.send(method))}\">")
      form_group lbl, fld, gopt
    end

    ##
    # Creates a standard form group with a datepicker field.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    # For field options, see #date_picker.
    #
    def datepicker_form_group(method, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lbl = label_w_small(method, lopt)
      fld = gopt[:wrap].call(date_picker(method, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a standard form group with a multiple input control.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    # For field options, see #multi_input_field.
    #
    def multi_input_form_group(methods, options = {})
      gopt, lopt, fopt = split_form_group_options(options)
      lopt[:text] ||= gopt[:label]
      if lopt[:text].blank?
        lopt[:text] = methods.map {|k,_| k.to_s.humanize }.join(', ')
      end
      lbl = label_w_small(methods.map{|k,_| k}.first, lopt)
      fld = gopt[:wrap].call(multi_input(methods, fopt))
      form_group lbl, fld, gopt
    end

    ##
    # Creates a standard form group with a checkbox field.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.
    #
    # h_align::
    #     Create a checkbox aligned to a certain column (1-12) if set.
    #     If not set, then a regular form group is generated.
    #
    # For label options, see #label_w_small.
    # For field options, see {FormHelper#check_box}[http://apidock.com/rails/ActionView/Helpers/FormHelper/check_box].
    #
    def check_box_form_group(method, options = {})
      gopt, lopt, fopt = split_form_group_options({ class: 'checkbox', field_class: ''}.merge(options))

      if gopt[:h_align]
        gopt[:class] = gopt[:class].blank? ?
            "col-sm-#{12-gopt[:h_align]} col-sm-offset-#{gopt[:h_align]}" :
            "#{gopt[:class]} col-sm-#{12-gopt[:h_align]} col-sm-offset-#{gopt[:h_align]}"
      end

      lbl = label method do
        check_box(method, fopt) +
            h(lopt[:text] || method.to_s.humanize) +
            (lopt[:small_text] ? " <small>(#{h lopt[:small_text]})</small>" : '').html_safe
      end

      "<div class=\"#{gopt[:h_align] ? 'row' : 'form-group'}\"><div class=\"#{gopt[:class]}\">#{lbl}</div></div>".html_safe
    end

    ##
    # Creates a standard form group with a collection select field.
    #
    # The +collection+ should be an enumerable object (responds to 'each').
    #
    # The +value_method+ would be the method to call on the objects in the collection to get the value.
    # This default to 'to_s' and is appropriate for any array of strings.
    #
    # The +text_method+ would be the method to call on the objects in the collection to get the display text.
    # This defaults to 'to_s' as well, and should be appropriate for most objects.
    #
    # The +options+ is a hash containing label, field, and group options.
    # Prefix label options with +label_+ and field options with +field_+.
    # All other options will apply to the group itself.
    #
    # Group options:
    #
    # class::
    #     The CSS class for the form group.  Defaults to 'form-group'.
    #
    # style::
    #     Any styles to apply to the form group.
    #
    # For label options, see #label_w_small.
    # For field options, see {FormOptionsHelper#collection_select}[http://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/collection_select].
    #
    def select_form_group(method, collection, value_method = :to_s, text_method = :to_s, options = {})
      gopt, lopt, fopt = split_form_group_options({ field_include_blank: true }.merge(options))
      lbl = label_w_small(method, lopt)
      opt = {}
      [:include_blank, :prompt, :include_hidden].each do |attr|
        if fopt[attr] != nil
          opt[attr] = fopt[attr]
          fopt.except! attr
        end
      end
      fld = gopt[:wrap].call(collection_select(method, collection, value_method, text_method, opt, fopt))
      form_group lbl, fld, gopt
    end


    private

    def form_group(lbl, fld, opt)
      ret = '<div'
      ret += " class=\"#{h opt[:class]}" unless opt[:class].blank?
      ret += '"'
      ret += " style=\"#{h opt[:style]}\"" unless opt[:style].blank?
      ret += ">#{lbl}#{fld}</div>"
      ret.html_safe
    end

    def split_form_group_options(options)
      options = {class: 'form-group', field_class: 'form-control'}.merge(options || {})
      group = {}
      label = {}
      field = {}

      options.keys.each do |k|
        sk = k.to_s
        if sk.index('label_') == 0
          label[sk[6..-1].to_sym] = options[k]
        elsif sk.index('field_') == 0
          field[sk[6..-1].to_sym] = options[k]
        else
          group[k.to_sym] = options[k]
        end
      end

      group[:wrap] = Proc.new do |fld|
        fld
      end
      if group[:h_align]
        if group[:h_align].is_a?(TrueClass)
          l = 3
        else
          l = group[:h_align].to_i
        end
        l = 1 if l < 1
        l = 6 if l > 6
        f = 12 - l
        group[:h_align] = l
        label[:class] = label[:class].blank? ? "col-sm-#{l} control-label" : "#{label[:class]} col-sm-#{l} control-label"
        group[:wrap] = Proc.new do |fld|
          "<div class=\"col-sm-#{f}\">#{fld}</div>"
        end
      end

      [group, label, field]
    end

  end
end

ActionView::Helpers::FormBuilder.include Incline::Extensions::FormBuilder