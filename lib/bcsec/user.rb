require 'bcsec'

module Bcsec
  class User
    ATTRIBUTES = :username, :first_name, :middle_name, :last_name,
      :title, :business_phone, :fax, :email, :address, :city, :state, :country,
      :nu_employee_id, :personnel_id, :portals, :group_memberships

    attr_accessor *ATTRIBUTES

    # Specifies a default portal to use for subsequent calls which
    # take a portal as a parameter.
    #
    # @return [Symbol, nil]
    attr_accessor :default_portal

    ##
    # Creates a new instance.
    #
    # @param [String] username the username for this new user
    # @param [Array<Symbol>] portals the portals to which this user
    #   has access.
    def initialize(username, portals=[])
      @username = username
      @portals = [*portals]
    end

    ##
    # @param [#to_sym] portal
    # @return [Boolean] true if the user has access, otherwise false
    def may_access?(portal)
      portals.include?(portal.to_sym)
    end

    ##
    # A display-friendly name for this user.  Uses `first_name` and
    # `last_name` if available, otherwise it just uses the username.
    #
    # @return [String]
    def full_name
      display_name_parts = [first_name, last_name].compact
      if display_name_parts.empty?
        username
      else
        display_name_parts.join(' ')
      end
    end

    ##
    # @param [#to_sym,nil] portal the portal to get the memberships
    #   for.  If nil, uses {#default_portal}.
    # @return [GroupMemberships] for a particular portal
    def group_memberships(portal=nil)
      portal = (portal || required_default_portal).to_sym
      @gms ||= { }
      @gms[portal] ||= GroupMemberships.new(portal)
    end

    def default_portal=(val)
      @default_portal = val.nil? ? nil : val.to_sym
    end

    protected

    def required_default_portal
      default_portal or raise "No default portal set.  Please specify one explicitly."
    end
  end
end

