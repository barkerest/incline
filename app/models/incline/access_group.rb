module Incline
  class AccessGroup < ActiveRecord::Base

    # hide the Groups<=>Users relationship association
    has_many :access_group_user_members, class_name: 'Incline::AccessGroupUserMember', foreign_key: 'group_id', dependent: :delete_all
    private :access_group_user_members, :access_group_user_members=

    # and expose the users instead.
    has_many :users, class_name: 'Incline::User', through: :access_group_user_members, source: :member

    # hide the Groups<=>Groups relationship association
    has_many :access_group_group_members, class_name: 'Incline::AccessGroupGroupMember', foreign_key: 'group_id', dependent: :delete_all
    private :access_group_group_members, :access_group_group_members=

    # and expose the groups instead.
    has_many :groups, class_name: 'AccessGroup', through: :access_group_group_members, source: :member

    ##
    # Gets a list of memberships for this group.  (Read-only)
    def memberships(refresh = false)
      @memberships = nil if refresh
      @memberships ||= AccessGroupGroupMember.where(member_id: id).includes(:group).map{|v| v.group}.to_a.freeze
    end

    validates :name,
              presence: true,
              length: { maximum: 100 },
              uniqueness: { case_sensitive: false }

    scope :sorted, ->{ order(:name) }

    ##
    # Determines if this group belongs to the specified group.
    def belongs_to?(group)
      group = AccessGroup.get(group) unless group.is_a?(::Incline::AccessGroup)
      return false unless group
      safe_belongs_to?(group)
    end

    ##
    # Gets a list of all the groups this group provides effective membership to.
    def effective_groups
      ret = [ self ]
      memberships.each do |m|
        unless ret.include?(m)  # prevent infinite recursion
          tmp = m.effective_groups
          tmp.each do |g|
            ret << g unless ret.include?(g)
          end
        end
      end
      ret.sort{|a,b| a.name <=> b.name}
    end

    ##
    # Gets the user IDs for the members of this group.
    def user_ids
      users.map{|u| u.id}
    end

    ##
    # Gets the group IDs for the members of this group.
    def group_ids
      groups.map{|g| g.id}
    end

    ##
    # Sets the user IDs for the members of this group.
    def user_ids=(values)
      values ||= []
      values = [ values ] unless values.is_a?(::Array)
      values = values.reject{|v| v.blank?}.map{|v| v.to_i}
      self.users = Incline::User.where(id: values).to_a
    end

    ##
    # Sets the group IDs for the members of this group.
    def group_ids=(values)
      values ||= []
      values = [ values ] unless values.is_a?(::Array)
      values = values.reject{|v| v.blank?}.map{|v| v.to_i}
      self.groups = Incline::AccessGroup.where(id: values).to_a
    end

    protected

    def safe_belongs_to?(group, already_tried = [])
      return true if self == group
      already_tried << self
      memberships.each do |parent|
        unless already_tried.include?(parent)
          return true if parent.safe_belongs_to?(group, already_tried)
        end
      end
      false
    end


  end
end
