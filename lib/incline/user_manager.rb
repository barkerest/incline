require 'net/ldap'

module Incline
  ##
  # Handles the user management tasks between an authentication system and the database.
  #
  # The default authentication system is the database, but other systems are supported.
  # Out of the box we support LDAP, but the class can be extended to add other functionality.
  #
  class UserManager

    ##
    # Creates a new user manager.
    def initialize(options = {})
      @options = (options || {}).symbolize_keys
      if @options[:enable_ldap_auth]
        @ldap = get_ldap_connection
        raise ArgumentError.new('Failed to connect to LDAP host using supplied arguments.') unless @ldap.bind
      end
      @options[:enable_db_auth] = true unless @options[:enable_ldap_auth]
      Incline::User.ensure_admin_exists!
    end

    ##
    # Is this user manager using ldap?
    def using_ldap?
      @options[:enable_ldap_auth]
    end

    ##
    # Is the user manager using ldap?
    def self.using_ldap?
      default.using_ldap?
    end

    ##
    # Is this user manager using the db?
    def using_db?
      @options[:enable_db_auth]
    end

    ##
    # Is the user manager using the db?
    def self.using_db?
      default.using_db?
    end

    ##
    # Gets the first authentication source for this user manager.
    def primary_source
      return :ldap if using_ldap? && !using_db?
      return :db if using_db? && !using_ldap?

      source = @options[:primary_source]
      source = source.to_sym if source.is_a?(String)

      return source if [:ldap, :db].include?(source)

      return :ldap if using_ldap?

      :db
    end

    ##
    # Gets the first authentication source for the user manager.
    def self.primary_source
      default.primary_source
    end

    ##
    # Attempts to authenticate the user and returns the model on success.
    def authenticate(email, password, client_ip)
      return nil unless Incline::EmailValidator.valid?(email)

      email = email.downcase

      sources.each do |source|
        if source == :ldap
          entry = @ldap.search(filter: "(&(objectClass=user)(mail=#{email}))")
          if entry && entry.count == 1  # we found a match.
            user = User.find_by(email: email, ldap: true)

            # make sure it authenticates correctly.
            entry = @ldap.bind_as(filter: "(&(objectClass=user)(mail=#{email}))", password: password)

            # do not allow authenticating against the DB now.
            unless entry && entry.count == 1
              add_failure_to (user || email), '(LDAP) failed to authenticate', client_ip
              return nil
            end

            # load the user and return.
            user = load_ldap_user(entry.first, true, client_ip)
            unless user.enabled?
              add_failure_to user, '(LDAP) account disabled', client_ip
              return nil
            end
            add_success_to user, '(LDAP)', client_ip
            return user
          end
        else
          user = User.find_by(email: email)
          if user
            # user must be enabled, cannot be LDAP, and the password must match.
            if user.ldap?
              add_failure_to user, '(DB) cannot authenticate LDAP user', client_ip
              return nil
            end
            unless user.enabled?
              add_failure_to user, '(DB) account disabled', client_ip
              return nil
            end
            if user.authenticate(password)
              add_success_to user, '(DB)', client_ip
              return user
            else
              add_failure_to user, '(DB) invalid password', client_ip
              return nil
            end
          end
        end
      end
      add_failure_to email, 'invalid email', client_ip
      nil
    end

    ##
    # Attempts to authenticate the user and returns the model on success.
    def self.authenticate(email, password, client_ip)
      default.authenticate email, password, client_ip
    end

    ##
    # Should valid ldap users be auto-activated on first login?
    def auto_activate_ldap?
      @options[:ldap_auto_activate]
    end

    ##
    # Should valid ldap users be auto-activated on first login?
    def self.auto_activate_ldap?
      default.auto_activate_ldap?
    end

    ##
    # Gets the list of ldap groups that map to system administrators.
    def ldap_system_admin_groups
      @ldap_system_admin_groups ||=
          begin
            val = @options[:ldap_system_admin_groups]
            val.blank? ? [] : val.strip.gsub(',', ';').split(';').map{|v| v.strip.upcase}
          end
    end

    ##
    # Gets the list of ldap groups that map to system administrators.
    def self.ldap_system_admin_groups
      default.ldap_system_admin_groups
    end

    private

    def purge_old_history_for(user, max_months = 2)
      user.login_histories.where('"user_login_histories"."created_at" <= ?', Time.zone.now - max_months.months).delete_all
    end

    def add_failure_to(user, message, client_ip)
      Incline::Log::info "LOGIN(#{user}) FAILURE FROM #{client_ip}: #{message}"
      history_length = 2
      unless user.is_a?(User)
        message = "[email: #{user}] #{message}"
        user = User.anonymous
        history_length = 6
      end
      purge_old_history_for user, history_length
      user.login_histories.create(ip_address: client_ip, successful: false, message: message)
    end

    def add_success_to(user, message, client_ip)
      Incline::Log::info "LOGIN(#{user}) SUCCESS FROM #{client_ip}: #{message}"
      purge_old_history_for user
      user.login_histories.create(ip_address: client_ip, successful: true, message: message)
    end

    def sources
      @sources ||=
          if using_ldap? && using_db?
            if primary_source == :db
              [ :db, :ldap ]
            else
              [ :ldap, :db ]
            end
          elsif using_ldap?
            [ :ldap ]
          else
            [ :db ]
          end
    end

    def self.auth_config
      @auth_config ||=
          begin
            cfg = Rails.root.join('config','auth.yml')
            if File.exist?(cfg)
              cfg = YAML.load_file(cfg)
              if cfg.is_a?(::Hash)
                cfg = cfg[Rails.env]
                (cfg || {}).symbolize_keys
              else
                {}
              end
            else
              {}
            end
          end
    end

    def self.default
      @default ||= UserManager.new(auth_config)
    end

    # Decode a binary SID into the common string form.
    # Used on AD servers to locate the primary group membership.
    # See http://blogs.msdn.com/b/oldnewthing/archive/2004/03/15/89753.aspx
    def self.decode_sid(binary_sid)

      # only support SID revision 1
      return false unless binary_sid && binary_sid[0].ord == 1

      ret = 'S-1-'

      dashes_remaining = binary_sid[1].ord

      # remove first 2 bytes and continue.
      binary_sid = binary_sid[2..-1]

      # first group is 48-bit big-endian.
      i = 0
      binary_sid[0..5].chars.each do |b|
        i = (i * 256) + b.ord
      end

      ret <<= i.to_s

      # remaining groups are 32-bit little-endian.
      binary_sid = binary_sid[6..-1]
      while dashes_remaining > 0
        i = 0
        binary_sid[0..3].reverse.chars.each do |b|
          i = (i * 256) + b.ord
        end
        ret <<= "-#{i}"
        dashes_remaining -= 1
        binary_sid = binary_sid[4..-1]
      end

      ret
    end


    def get_ldap_connection
      ldap = Net::LDAP.new(host: @options[:ldap_host], port: @options[:ldap_port], base: @options[:ldap_base_dn])
      ssl = @options[:ldap_ssl]
      ssl = ssl.to_s.downcase
      ssl = true if ssl == 'true'
      ssl = false if ssl == 'false' || ssl == '' || ssl == 'nil'
      ssl = ssl.to_sym if ssl.is_a?(String)

      if ssl
        if ssl == :simple_tls
          ldap.encryption method: :simple_tls
        elsif ssl == :start_tls
          ldap.encryption method: :start_tls
        else
          if @options[:ldap_port] == 389
            ldap.encryption method: :start_tls
          else
            ldap.encryption method: :simple_tls
          end
        end
      end

      if @options[:ldap_browse_user]
        ldap.authenticate @options[:ldap_browse_user], @options[:ldap_browse_password]
      end

      ldap
    end

    def attrib_val(entry, attr)
      return nil unless entry.attribute_names.include?(attr)
      val = entry[attr]
      val = val.first if val && val.respond_to?(:first)
      val
    end

    def first_attrib_val(entry, *attr)
      attr.each do |a|
        v = attrib_val(entry, a)
        return v if v
      end
      nil
    end

    def group_to_groups(group_entry, existing_groups)
      return [] unless group_entry

      ret = []

      # get the group name.

      name = first_attrib_val(group_entry, :samaccountname, :name, :cn)

      return [] unless name

      name.upcase!

      # do not duplicate entries.  this will also prevent the possibility of infinite recursion.
      unless existing_groups.index { |x| x == name } || ret.index { |x| x == name }

        # add this group.
        ret <<= name

        # if the group belongs to parent groups, add them as well.
        if group_entry[:memberof] && group_entry[:memberof].respond_to?('each')
          group_entry[:memberof].each do |dn|
            parent_entry = @ldap.search(base: dn).first
            ret += group_to_groups(parent_entry, ret + existing_groups)
          end
        end
      end

      ret
    end

    def load_ldap_user(entry, update_permissions = false, client_ip = '0.0.0.0')

      # email is our unique identifier
      email = attrib_val(entry, :mail)
      return nil unless email
      email.downcase!

      # grab the SID and find the user.
      ret = User.find_by(email: email)
      pwd = SecureRandom.urlsafe_base64(53) # should generate a 71 character string.
                                            # max supported by has_secure_password is 72 characters.

      if ret
        # set ldap flag and change to random password.
        ret.ldap = true
        ret.password = ret.password_confirmation = pwd
      else
        # create new user with random password.
        ret = User.create!(
            name:                   email,
            email:                  email,
            password:               pwd,
            password_confirmation:  pwd,
            enabled:                true
        )

        if auto_activate_ldap?
          ret.activate
        else
          ret.send_activation_email(client_ip)
        end
      end

      # update the user attributes in the database.
      ret.name = first_attrib_val(entry, :displayname, :givenname, :name, :cn)
      ret.ldap = true
      ret.save!

      if update_permissions
        # now we need the user group memberships from ldap
        # once we get those, we can translate them over.
        groups = []
        entry[:memberof].each do |dn|
          # load the group and get the group name (always in uppercase)
          group_entry = @ldap.search(base: dn).first
          groups += group_to_groups(group_entry, groups)
        end

        # there may be one missing group still, the default group is not included in the 'memberOf' attribute.
        if (group_rid = attrib_val(entry, :primarygroupid))
          # the primary group id is the relative ID within the domain SID for the group.
          # so we'll get the domain SID from the user SID and append the group RID.
          user_sid = UserManager.decode_sid(attrib_val(entry, :objectsid))
          if user_sid
            domain_sid = user_sid.rpartition('-')[0]
            group_sid = "#{domain_sid}-#{group_rid}"

            # the search takes the SID in string form, not in binary form (like in other places).
            group_entry = @ldap.search(filter: "(&(objectClass=group)(objectSID=#{group_sid}))")

            # did we locate the group?
            if group_entry && group_entry.count == 1
              groups += group_to_groups(group_entry.first, groups)
            else
              Rails.logger.warn "WARNING: Failed to locate group with SID=#{group_sid}"
            end
          end
        end

        # so now 'groups' contains a list of every ldap group the user belongs to.
        ret.system_admin = false
        ldap_system_admin_groups.each do |group|
          ret.system_admin = true if groups.include?(group)
        end

        access_groups = []
        groups.each do |group|
          access_group = AccessGroup.find_by(name: group)
          access_groups << access_group.group if access_group && !access_groups.include?(access_group.group)
        end

        ret.groups = access_groups
        ret.save!
      end

      ret
    end

  end
end
