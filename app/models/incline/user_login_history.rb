module Incline
  class UserLoginHistory < ActiveRecord::Base
    belongs_to :user
  end
end
