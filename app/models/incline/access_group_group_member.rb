module Incline
  class AccessGroupGroupMember < ActiveRecord::Base
    belongs_to :group, class_name: 'Incline::AccessGroup'
    belongs_to :member, class_name: 'Incline::AccessGroup'

    validates :group_id, presence: true
    validates :member_id, presence: true, uniqueness: { scope: :group_id }

    # member_id should not equal group_id or cause infinite recursion.
    # these two issues are addressed in the AccessGroup model.
  end
end
