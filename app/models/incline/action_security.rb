require_relative './action_group'

module Incline
  class ActionSecurity < ActiveRecord::Base

    SHORT_PERMITTED_FILTERS = {
        '- Editable -' => 'users|custom',
        'Admins' => 'admins',
        'Anon' => 'anon',
        'Custom' => 'custom',
        'Everyone' => 'everyone',
        'Users' => 'users'
    }.freeze

    has_many :action_groups
    private :action_groups, :action_groups=

    has_many :groups, through: :action_groups, class_name: 'Incline::AccessGroup', source: :access_group

    validates :controller_name, presence: true, length: { maximum: 200 }
    validates :action_name, presence: true, length: { maximum: 200 }, uniqueness: { scope: :controller_name, case_sensitive: false }
    validates :path, presence: true

    before_save :downcase_names

    scope :visible, ->{ where(visible: true) }

    ##
    # Updates the flags based on the controller configuration.
    def update_flags
      self.allow_anon = self.require_anon = self.require_admin = self.unknown_controller = self.non_standard = false

      self.unknown_controller = true
      klass = ::Incline.get_controller_class(controller_name)

      if klass
        self.unknown_controller = false
        if klass.require_admin_for?(action_name)
          self.require_admin = true
        elsif klass.require_anon_for?(action_name)
          self.require_anon = true
        elsif klass.allow_anon_for?(action_name)
          self.allow_anon = true
        end

        # if the authentication methods are overridden, set a flag to alert the user that standard security may not be honored.
        unless klass.instance_method(:valid_user?).owner == Incline::Extensions::ActionControllerBase &&
            klass.instance_method(:authorize!).owner == Incline::Extensions::ActionControllerBase
          self.non_standard = true
        end

      end

    end

    ##
    # Determines if the action allows custom security settings.
    def allow_custom?
      !(require_admin? || require_anon? || allow_anon?)
    end

    ##
    # Generates a list of security items related to all of the current routes in the application.
    #
    # If "refresh" is true, the list will be rebuilt.
    # If "update_flags" is true, the individual controllers will be loaded to regenerate the flags for the security.
    #
    # The returned list can be indexed two ways.  The normal way with a numeric index and also by specifying the
    # controller_name and action_name.
    #
    #     Incline::ActionSecurity.valid_items[0]
    #     Incline::ActionSecurity.valid_items['incline/welcome','home']
    #
    def self.valid_items(refresh = false, update_flags = true)
      @valid_items = nil if refresh
      @valid_items ||=
          begin
            # remove all paths and set all items to hidden.
            Incline::ActionSecurity.update_all(visible: false, path: '#')

            ret = Incline
                      .route_list
                      .reject{|r| %w(api locate).include?(r[:action]) }
                      .map do |r|
              
              item = ActionSecurity.find_or_initialize_by(controller_name: r[:controller], action_name: r[:action])
              
              # ensure the current path is set to the item.
              item_path = "#{r[:path]} [#{r[:verb]}]"
              if item.path == '#' || item.path.blank?
                item.path = item_path
                # only update the flags once if the path has not yet been set.
                item.update_flags if update_flags
              elsif !item.path.include?(item_path)
                item.path += "\n" + item_path
              end
              
              # re-sort the path list and make the item visible.
              item.path = item.path.split("\n").sort.join("\n")
              item.visible = true
              
              item.save!
              item
            end.sort do |a,b|
              if a.controller_name == b.controller_name
                a.action_name <=> b.action_name
              else
                a.controller_name <=> b.controller_name
              end
            end

            def ret.[](*args)
              if args.length == 2
                controller = args[0].to_s
                action = args[1].to_s
                find{|item| item.controller_name == controller && item.action_name == action}
              else
                super(*args)
              end
            end

            ret.freeze
          end
    end

    ##
    # Gets a string describing who is permitted to execute the action.
    def permitted(refresh = false)
      @permitted = nil if refresh
      @permitted ||=
          if require_admin?
            'Administrators Only'
          elsif require_anon?
            'Anonymous Only'
          elsif allow_anon?
            'Everyone'
          elsif groups.any?
            names = groups.pluck(:name).map{|v| "\"#{v}\""}
            'Members of ' +
                if names.count == 1
                  names.first
                elsif names.count == 2
                  names.join(' or ')
                else
                  names[0...-1].join(', ') + ', or ' + names.last
                end
          else
            'All Users'
          end +
              if non_standard
                ' (Non-Standard)'
              else
                ''
              end
    end

    ##
    # Gets a short string describing who is permitted to execute the action.
    def short_permitted
      if require_admin?
        'Admins'
      elsif require_anon?
        'Anon'
      elsif allow_anon?
        'Everyone'
      elsif groups.any?
        'Custom'
      else
        'Users'
      end +
          if non_standard
            '*'
          else
            ''
          end
    end

    ##
    # Description of action.
    def to_s
      @to_s ||= "#{controller_name}:#{action_name} [#{permitted}]"
    end

    ##
    # Gets the group IDs accepted by this action.
    def group_ids
      groups.pluck(:id)
    end

    ##
    # Sets the group IDs accepted by this action.
    def group_ids=(values)
      values ||= []
      values = [ values ] unless values.is_a?(::Array)
      values = values.reject{|v| v.blank?}.map{|v| v.to_i}
      self.groups = Incline::AccessGroup.where(id: values).to_a
    end

    private

    def downcase_names
      controller_name.downcase!
      action_name.downcase!
    end

  end
end
