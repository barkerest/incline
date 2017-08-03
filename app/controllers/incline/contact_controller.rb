module Incline
  class ContactController < ApplicationController

    allow_anon true

    ##
    # GET /incline/contact
    def new
      @msg = Incline::ContactMessage.new
    end

    ##
    # POST /incline/contact
    def create
      @msg = get_message
      if @msg.valid?
        @msg.remote_ip = request.remote_ip
        @msg.send_message
        flash[:success] = 'Your message has been sent.'
        redirect_to main_app.root_url
      else
        render 'new'
      end
    end

    private

    def get_message
      p = params.require(:contact_message).permit(:your_name, :your_email, :related_to, :subject, :body, :recaptcha)
      Incline::ContactMessage.new(p)
    end

  end
end
