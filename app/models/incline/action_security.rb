module Incline
  class ActionSecurity < ActiveRecord::Base

    has_many :action_groups
    private :action_groups, :action_groups=

    has_many :groups, through: :action_groups, class_name: 'Incline::AccessGroup', source: :access_group

    validates :controller_name, presence: true, length: { maximum: 200 }
    validates :action_name, presence: true, length: { maximum: 200 }, uniqueness: { scope: :controller_name }
    validates :path, presence: true

    ##
    # Updates the flags based on the controller configuration.
    def update_flags
      self.allow_anon = self.require_anon = self.require_admin = self.unknown_controller = false

      options =
          if controller_name.include?('/')
            ns = controller_name.rpartition('/')[0]
            ctrl = controller_name.rpartition('/')[2]
            options = [
                "#{ns}/app/controllers/#{ns}/#{ctrl}_controller",
                "app/controllers/#{ns}/#{ctrl}_controller",
                "#{ns}/app/controllers/#{ctrl}_controller",
                "#{ns}/#{ctrl}_controller"
            ]
          else
            options = [
                "app/controllers/#{controller_name}_controller",
                "#{controller_name}_controller"
            ]
          end

      self.unknown_controller = true
      klass = nil
      while (file = options.shift)
        begin
          require file
          klass = (controller_name + '_controller').classify.constantize
          break
        rescue LoadError, NameError
          # just preventing the error from bubbling up.
        end
      end

      if klass
        self.unknown_controller = false
        if klass.require_admin_for?(action_name)
          self.require_admin = true
        elsif klass.require_anon_for?(action_name)
          self.require_anon = true
        elsif klass.allow_anon_for?(action_name)
          self.allow_anon = true
        end
      end

    end

    ##
    # Determines if the action allows custom security settings.
    def allow_custom?
      !(require_admin? || require_anon? || allow_anon?)
    end

    ##
    # Gets all of the actions with valid routes for the current application.
    def self.valid_items(refresh = false)
      @valid_items = nil if refresh
      @valid_items ||=
          Incline.route_list.map do |r|
            item = ActionSecurity.find_or_initialize_by(controller_name: r[:controller], action_name: r[:action])
            item.path = "#{r[:path]} [#{r[:verb]}]"
            item.update_flags
            item.save!
            item
          end
    end

    ##
    # Gets a string describing who is permitted to execute the action.
    def permitted
      @permitted ||=
          if require_admin?
            'Administrators Only'
          elsif require_anon?
            'Anonymous Only'
          elsif allow_anon?
            'Everyone'
          elsif groups.any?
            names = groups.pluck(:name)
            'Members of ' +
                if names.count == 1
                  names.first
                else
                  names[0...-1].join(', ') + 'or ' + names.last
                end
          else
            'All Users'
          end
    end

    ##
    # Description of action.
    def to_s
      @to_s ||= "#{controller_name}:#{action_name} [#{permitted}]"
    end



  end
end
