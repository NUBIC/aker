require 'aker'
require 'yaml'

module Aker::Authorities
  ##
  # An authority which is configured entirely in memory.  It's not
  # intended for production, but rather for testing (particularly
  # integrated testing) and bootstrapping (e.g., for rapidly testing
  # out aker in an application before setting up the infrastructure
  # needed for {Ldap} or a custom authority).
  class Static
    ##
    # Creates a new instance.  Does not use any configuration properties.
    def initialize(ignored=nil)
      self.clear
    end

    ##
    # Creates a new instance from a file.  You can use the result of
    # this method directly in a Aker configuration block.  E.g.:
    #
    #     Aker.configure {
    #       authority Aker::Authorities::Static.from_file(File.expand_path("../static-auth.yml", __FILE__))
    #     }
    #
    # @param [String] filename the name of a YAML file containing the
    #   format outlined for {#load!}
    #
    # @return [Static] a new instance
    #
    # @see #load! the file format
    def self.from_file(filename)
      File.open(filename) { |f| self.new.load!(f) }
    end

    ###### AUTHORITY API IMPLEMENTATION

    ##
    # Verifies the credentials against the set provided by calls to
    # {#valid_credentials!} and {#load!}.  Supports all kinds.
    #
    # @return [Aker::User, nil]
    def valid_credentials?(kind, *credentials)
      found_username =
        (all_credentials(kind).detect { |c| c[:credentials] == credentials } || {})[:username]
      @users[found_username]
    end

    ##
    # Merges in the authorization information in this authority for the
    # given user.
    #
    # @param [Aker::User] user the target user
    #
    # @return [Aker::User] the input user, modified
    def amplify!(user)
      base = @users[user.username]
      return user unless base

      user.merge!(base)
    end

    ##
    # Returns the any users which match the given criteria from the
    # set that have been loaded with {#load!}, {#valid_credentials!},
    # and {#user}.
    #
    # @param [Array<Hash,#to_s>] criteria as described in
    #   {Composite#find_users}.
    # @return [Array<Aker::User>]
    def find_users(*criteria)
      criteria.collect do |criteria_group|
        unless Hash === criteria_group
          criteria_group = { :username => criteria_group.to_s }
        end
        props = criteria_group.keys.select { |k|
          Aker::User.instance_methods.include?(k.to_s) || # for 1.8.7
          Aker::User.instance_methods.include?(k.to_sym)  # for 1.9.1
        }
        if props.empty?
          []
        else
          @users.values.select do |user|
            props.inject(true) { |result, prop| result && user.send(prop) == criteria_group[prop] }
          end
        end
      end.flatten.uniq
    end

    ###### SETUP METHODS

    ##
    # Creates or updates one of the user records in this authority.  If
    # provided a block, the user will be yielded to it.  This the
    # mechanism to use to set attributes, portals, and group
    # memberships on the users returned by {#valid_credentials?}.
    # Example:
    #
    #     auth.user("wakibbe") do |u|
    #       u.first_name = "Warren"
    #       u.portals << :ENU
    #     end
    #
    #     auth.user("wakibbe").first_name # => "Warren"
    #
    # @param [String] username the username for the user to create,
    #   update, or just read
    #
    # @return [Aker::User] the single user for `username` (possibly
    #   newly created; never nil)
    #
    # @see #load!
    def user(username, &block)
      u = (@users[username] ||= Aker::User.new(username))
      u.tap(&block) if block
      u
    end

    ##
    # Associate the given set of credentials of a particular kind with
    # the specified user.  Note that all kinds require a username
    # (unlike with {#valid_credentials?}).  Examples:
    #
    #     auth.valid_credentials!(:user, "wakibbe", "ekibder")
    #     auth.valid_credentials!(:api_key, "notis-app", "12345-67890")
    #
    # For further user customization, you can pass a block.  This block
    # receives an object that responds to all {Aker::User} methods as well as
    # helper methods for setting up portal and group memberships.
    # Examples:
    #
    #     auth.valid_credentials!(:user, "wakibbe", "ekibder") do |u|
    #       # grants access to portal :ENU
    #       u.in_portal!(:ENU)
    #
    #       # sets up name data
    #       u.first_name = 'Warren'
    #       u.last_name = 'Kibbe'
    #     end
    #
    #     auth.valid_credentials!(:user, "wakibbe", "ekibder") do |u|
    #       # grants access to portal :ENU and membership in group "User"
    #       u.in_group!(:ENU, "User")
    #     end
    #
    #     auth.valid_credentials!(:api_key, "notis-ns", "12345-67890") do |u|
    #       # grants access to portal :NOTIS and membership in group "Auditor"
    #       for affiliates 20 and 30
    #       u.in_group!(:NOTIS, "Auditor", :affiliate_ids => [20, 30])
    #     end
    #
    # @param [Symbol] kind the kind of credentials these are.
    #   Anything is allowed.
    # @param [String] username the username for the user which is
    #   authenticated by these credentials.
    # @param [Array<String>,nil] *credentials the credentials
    #   themselves.  (Note that you need not repeat the username for
    #   the :user kind.)
    # @yield [user] a user object as described above
    #
    # @return [void]
    def valid_credentials!(kind, username, *credentials)
      if kind == :user
        credentials = [username, *credentials]
      end
      all_credentials(kind) << { :username => username, :credentials =>  credentials }
      @users[username] ||= Aker::User.new(username)

      yield UserBuilder.new(@users[username], self) if block_given?
    end

    ##
    # Loads a YAML doc and uses its contents to initialize the
    # authority's authentication and authorization data.
    #
    # Sample doc:
    #
    #     users:
    #       wakibbe:               # username
    #         password: ekibder    # password for :user auth (optional)
    #         first_name: Warren   # any attributes from Aker::User may
    #         last_name: Kibbe     #   be set here
    #         identifiers:         # identifiers will be loaded with
    #           employee_id: 4     # symbolized keys
    #         portals:             # portal & group auth info (optional)
    #           - SQLSubmit        # A groupless portal
    #           - ENU:             # A portal with simple groups
    #             - User
    #           - NOTIS:           # A portal with affiliated groups
    #             - Manager: [23]
    #             - User           # you can mix affiliated and simple
    #
    #     groups:                  # groups for hierarchical portals
    #       NOTIS:                 # (these aren't real NOTIS groups)
    #         - Admin:
    #           - Manager:
    #             - User
    #           - Auditor
    #
    # @param [#read] io a readable handle (something that can be passed to
    #   `YAML.load`)
    #
    # @return [Static] self
    def load!(io)
      doc = YAML.load(io)
      return self unless doc
      (doc["groups"] || {}).each do |portal, top_level_groups|
        @groups[portal.to_sym] = top_level_groups.collect { |group_data| build_group(group_data) }
      end
      (doc["users"] || {}).each do |username, config|
        attr_keys = config.keys - ["password", "portals", "identifiers"]

        valid_credentials!(:user, username, config["password"]) do |u|
          attr_keys.each do |k|
            begin
              u.send("#{k}=", config[k])
            rescue NoMethodError
              raise NoMethodError, "#{k} is not a recognized user attribute"
            end
          end

          portal_data = config["portals"] || []

          portals_and_groups_from_yaml(portal_data) do |portal, group, affiliate_ids|
            u.default_portal = portal unless u.default_portal

            u.in_portal!(portal)

            if group
              if affiliate_ids
                u.in_group!(portal, group, :affiliate_ids => affiliate_ids)
              else
                u.in_group!(portal, group)
              end
            end
          end

          (config["identifiers"] || {}).each do |ident, value|
            u.identifiers[ident.to_sym] = value
          end
        end
      end

      self
    end

    ##
    #
    # This method interprets three different portal/group specification types.
    #
    # Type 1:
    #     - SQLSubmit
    #
    # Type 2:
    #     - ENU:
    #       - User
    #
    # Type 3:
    #     - NOTIS:
    #       - Manager: [23]
    #
    # @private
    def portals_and_groups_from_yaml(portal_data, &block)
      portal_data.each do |datum|
        if datum.is_a?(String)
          block.call(datum.to_sym, nil, nil)
        elsif datum.is_a?(Hash)
          portal = datum.keys.first.to_sym
          group_data = datum.values.first
          groups_from_yaml(portal, group_data, block)
        end
      end
    end

    ##
    # @private
    def groups_from_yaml(portal, group_data, block)
      group_data.each do |datum|
        if datum.is_a?(String)
          block.call(portal, datum, nil)
        elsif datum.is_a?(Hash)
          group = datum.keys.first
          affiliate_ids = datum.values.first
          block.call(portal, group, affiliate_ids)
        end
      end
    end

    ##
    # Resets the user and authorization data to the same state it was
    # in at initialization.
    #
    # @return [Static] self
    def clear
      @groups = {}
      @users = {}
      @credentials = {}
      self
    end

    ##
    # @private
    # @return [Aker::Group]
    def find_or_create_group(portal, group_name)
      existing = (@groups[portal] ||= []).collect { |top|
        top.find { |g| g.name == group_name }
      }.compact.first
      return existing if existing
      @groups[portal] << Aker::Group.new(group_name)
      @groups[portal].last
    end

    private

    def all_credentials(kind)
      @credentials[kind] ||= []
    end

    def build_group(group_data)
      group_name, children =
        if String === group_data
          [group_data, []]
        else
          group_data.to_a.first
        end

      group = Aker::Group.new(group_name)
      children.each do |ch_group_data|
        group << build_group(ch_group_data)
      end
      group
    end

    # BlankSlate makes changes at a very deep level in the Ruby object
    # hierarchy.  Although it (probably) has been well-tested, there's no need
    # to load it up if we don't need it.
    if !defined?(BasicObject)
      require 'blankslate'
    end

    ##
    # Used by {#valid_credentials!} to wrap {Aker::User} objects with
    # group-setup helpers.
    #
    # This class uses BasicObject if it is present, BlankSlate otherwise.
    #
    # @private
    class UserBuilder < defined?(BasicObject) ? BasicObject : BlankSlate
      def initialize(user, authority)
        @user = user
        @authority = authority
      end

      def in_portal!(portal)
        @user.portals |= [portal.to_sym]
      end

      def in_group!(portal, group, options = {})
        in_portal!(portal)

        affiliate_ids = options.delete(:affiliate_ids)

        group = @authority.find_or_create_group(portal, group)
        gm = ::Aker::GroupMembership.new(group)
        gm.affiliate_ids = affiliate_ids if affiliate_ids
        gms = @user.group_memberships(portal)

        gms << gm
      end

      def method_missing(method, *args, &block)
        @user.send(method, *args, &block)
      end
    end
  end
end
