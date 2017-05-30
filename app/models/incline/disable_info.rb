module Incline
  ##
  # This model is used to disable a user with a reason for the disabling.
  class DisableInfo
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :reason, :user

    validates :reason, presence: true
    validate do
      if user && user.is_a?(::Incline::User)
        errors.add(:user, 'must be enabled') unless user.enabled?
      else
        errors.add(:user, 'must be provided')
      end
    end

  end
end
