module Incline
  ##
  # Defines the message generated by the generic contact form.
  class ContactMessage
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :your_name, :your_email, :related_to, :subject, :body, :remote_ip, :recaptcha

    validates :your_name, presence: true
    validates :your_email, presence: true, 'incline/email' => true
    validates :related_to, presence: true
    validates :subject, presence: true, if: :need_subject?
    validates :body, presence: true
    validates :recaptcha, 'incline/recaptcha' => true

    ##
    # Gets the full subject for the message.
    def full_subject
      return related_to if subject.blank?
      "#{related_to}: #{subject}"
    end

    ##
    # Sends the message.
    def send_message
      Incline::ContactForm.contact(self).deliver_now
    end

    private

    def need_subject?
      related_to.to_s.downcase == 'other'
    end

  end
end