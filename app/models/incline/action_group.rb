module Incline
  class ActionGroup < ActiveRecord::Base
    belongs_to :action_security
    belongs_to :access_group

    validates :action_security, presence: true
    validates :access_group, presence: true

  end
end
