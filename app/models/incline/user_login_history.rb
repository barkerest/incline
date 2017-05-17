module Incline
  class UserLoginHistory < ActiveRecord::Base

    belongs_to :user
    after_save :update_user_comments

    validates :user, presence: true
    validates :ip_address, presence: true, length: { maximum: 64 }, 'incline/ip_address' => { no_mask: true }
    validates :message, length: { maximum: 200 }

    def time_and_ip
      "#{created_at.in_time_zone.strftime('%m/%d/%Y %H:%M')} from #{ip_address}"
    end

    def date_and_ip
      "#{created_at.in_time_zone.strftime('%m/%d/%Y')} from #{ip_address}"
    end

    def to_s
      "Login #{successful ? 'succeeded' : 'failed'} on #{time_and_ip}"
    end

    private

    def update_user_comments
      user.refresh_comments
    end

  end
end
