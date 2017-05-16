module Incline
  class AccessGroupUserMember < ActiveRecord::Base

    belongs_to :group, class_name: 'Incline::AccessGroup'
    belongs_to :member, class_name: 'Incline::User'

    validates :group_id, presence: true
    validates :member_id, presence: true, uniqueness: { scope: :group_id }
  end
end
