require 'test_helper'

class FormBuilderExtensionsTest < ActiveSupport::TestCase

  def setup
    @builder = ActionView::Helpers::FormBuilder.new('my_object', Object.new, 'no template', { })
  end

  test 'should have additional methods' do
    assert @builder.respond_to?(:date_picker)
    assert @builder.respond_to?(:multi_input)
    assert @builder.respond_to?(:currency_field)
    assert @builder.respond_to?(:label_w_small)
    assert @builder.respond_to?(:text_form_group)
    assert @builder.respond_to?(:password_form_group)
    assert @builder.respond_to?(:textarea_form_group)
    assert @builder.respond_to?(:currency_form_group)
    assert @builder.respond_to?(:static_form_group)
    assert @builder.respond_to?(:datepicker_form_group)
    assert @builder.respond_to?(:multi_input_form_group)
    assert @builder.respond_to?(:check_box_form_group)
    assert @builder.respond_to?(:select_form_group)
    assert @builder.respond_to?(:recaptcha)
  end

  # TODO: Test output of various methods.

end