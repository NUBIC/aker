require 'bcsec'
require 'yaml'

module Bcsec::Authorities
  ##
  # An authority which is configured entirely in memory.  It's not
  # intended for production, but rather for testing (particularly
  # integrated testing) and bootstrapping (e.g., for rapidly testing
  # out bcsec in an application before setting up the infrastructure
  # needed for {Bcsec::Authorities::Pers Pers} or {Netid}).
  class Static
    ##
    # Creates a new instance.  Does not use any configuration properties.
    def initialize(ignored=nil)
      self.clear
    end

    ##
    # Creates a new instance from a file.  You can use the result of
    # this method directly in a Bcsec configuration block.  E.g.:
    #
    #     Bcsec.configure {
    #       authority Bcsec::Authorities::Static.from_file(File.expand_path("../static-auth.yml", __FILE__))
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
    # @return [Bcsec::User, nil]
    def valid_credentials?(kind, *credentials)
      found_username =
        (all_credentials(kind).detect { |c| c[:credentials] == credentials } || {})[:username]
      @users[found_username]
    end

    ##
    # Merges in the authorization information in this authority for the
    # given user.
    #
    # @param [Bcsec::User] user the target user
    #
    # @return [Bcsec::User] the input user, modified
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
    # @return [Array<Bcsec::User>]
    def find_users(*criteria)
      criteria.collect do |criteria_group|
        unless Hash === criteria_group
          criteria_group = { :username => criteria_group.to_s }
        end
        props = criteria_group.keys.select { |k|
          Bcsec::User.instance_methods.include?(k.to_s) || # for 1.8.7
          Bcsec::User.instance_methods.include?(k.to_sym)  # for 1.9.1
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
    # @return [Bcsec::User] the single user for `username` (possibly
    #   newly created; never nil)
    #
    # @see #load!
    def user(username, &block)
      u = (@users[username] ||= Bcsec::User.new(username))
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
    # @param [Symbol] kind the kind of credentials these are.
    #   Anything is allowed.
    # @param [String] username the username for the user which is
    #   authenticated by these credentials.
    # @param [Array<String>,nil] *credentials the credentials
    #   themselves.  (Note that you need not repeat the username for
    #   the :user kind.)
    #
    # @return [void]
    def valid_credentials!(kind, username, *credentials)
      if kind == :user
        credentials = [username, *credentials]
      end
      all_credentials(kind) << { :username => username, :credentials =>  credentials }
      @users[username] ||= Bcsec::User.new(username)
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
    #         first_name: Warren   # any attributes from Bcsec::User may
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
        valid_credentials!(:user, username, config["password"]) if config["password"]
        user(username) do |u|
          attr_keys = config.keys
          (attr_keys - ["password", "portals", "identifiers"]).each do |k|
            setter = "#{k}="
            if u.respond_to?(setter)
              u.send(setter, config[k])
            end
          end

          (config["portals"] || []).each do |portal_data|
            portal, group_data =
              if String === portal_data
                portal_data
              else
                portal_data.to_a.first
              end

            u.default_portal = portal unless u.default_portal

            u.portals << portal.to_sym
            if group_data
              u.group_memberships(portal).concat(load_group_memberships(portal.to_sym, group_data))
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

      group = Bcsec::Group.new(group_name)
      children.each do |ch_group_data|
        group << build_group(ch_group_data)
      end
      group
    end

    ##
    # Transform the group membership info from the static yaml format
    # into {Bcsec::GroupMembership} instances.
    #
    # @param [Array<String,Hash<String,Array<Fixnum>>>] group_data
    def load_group_memberships(portal, group_data)
      group_data.collect do |entry|
        group, affiliates =
          if String === entry
            entry
          else
            entry.to_a.first
          end

        gm = Bcsec::GroupMembership.new(find_or_create_group(portal, group))
        if affiliates
          gm.affiliate_ids = affiliates
        end
        gm
      end
    end

    # @return [Bcsec::Group]
    def find_or_create_group(portal, group_name)
      existing = (@groups[portal] ||= []).collect { |top|
        top.find { |g| g.name == group_name }
      }.compact.first
      return existing if existing
      @groups[portal] << Bcsec::Group.new(group_name)
      @groups[portal].last
    end
  end
end
