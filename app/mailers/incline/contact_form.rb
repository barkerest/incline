
module Incline
  ##
  # This mailer is used for the generic contact form.
  class ContactForm < ::Incline::ApplicationMailerBase

    ##
    # Sends the message from the contact form.
    def contact(msg)
      @data = {
          msg: msg,
          client_ip: msg.remote_ip,
          gems: BarkestCore.gem_list(Rails.application.class.parent_name.underscore, 'rails', 'barkest*'),  # FIXME
      }
      mail subject: msg.full_subject, reply_to: msg.your_email
    end
  end

end
