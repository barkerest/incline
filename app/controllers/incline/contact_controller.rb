module Incline
  class ContactController < ApplicationController

    ##
    # GET /incline/contact
    def index
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
        redirect_to root_url
      else
        render 'index'
      end
    end

    private

    def get_message
      Incline::ContactMessage.new(params.require(:contact_message).permit(:your_name, :your_email, :related_to, :subject, :body))
    end

  end
end
