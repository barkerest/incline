require 'test_helper'

module Incline
  class ContactControllerTest < ::ActionDispatch::IntegrationTest

    access_tests_for :new,
                     url_helper:      'incline.contact_path',
                     allow_anon:      true,
                     allow_any_user:  true,
                     allow_admin:     true

    access_tests_for :create,
                     method:          :post,
                     url_helper:      'incline.contact_path',
                     success:         'main_app.root_path',
                     allow_anon:      true,
                     allow_any_user:  true,
                     allow_admin:     true,
                     create_params: {
                         contact_message: {
                             your_name:   'John Doe',
                             your_email:  'jdoe@example.com',
                             related_to:  'Other',
                             subject:     'Just a test',
                             body:        'This is only a test.',
                             recaptcha:   Incline::Recaptcha::DISABLED
                         }
                     }


  end
end