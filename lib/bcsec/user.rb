require 'bcsec'

module Bcsec
  class User
    ATTRIBUTES = :username, :first_name, :middle_name, :last_name,
      :title, :business_phone, :fax, :email, :address, :city, :state, :country,
      :nu_employee_id, :personnel_id

    attr_accessor *ATTRIBUTES

    ##
    # Specifies a default portal to use for subsequent calls which
    # take a portal as a parameter.
    #
    # @return [Symbol, nil]
    attr_accessor :default_portal

    ##
    # The portals to which this user has access.
    #
    # @return [Array<Symbol>]
    # @see #may_access?
    attr_accessor :portals

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

    def portals
      @portals ||= []
    end

    ##
    # Exposes the {GroupMemberships group memberships} for a
    # this user on a particular portal.
    #
    # This method never returns `nil`.  Therefore, its return value
    # should not be used to determine if a user has access to a portal
    # &mdash; only for groups.  Use {#may_access?} to determine portal
    # access.
    #
    # @param [#to_sym,nil] portal the portal to get the memberships
    #   for.  If nil, uses {#default_portal}.
    #
    # @return [GroupMemberships] for a particular portal
    #
    # @see GroupMemberships#include?
    def group_memberships(portal=nil)
      portal = (portal || required_default_portal).to_sym
      all_group_memberships[portal] ||= GroupMemberships.new(portal)
    end

    ##
    # Exposes all the group memberships that this instance knows
    # about.  In general, {#group_memberships} is preferred unless you
    # really need to iterate over everything.
    #
    # @return [Hash<Symbol, GroupMemberships>]
    def all_group_memberships
      @gms ||= {}
    end

    def default_portal=(val)
      @default_portal = val.nil? ? nil : val.to_sym
    end

    ##
    # Modifies this user record in place, adding attributes from the
    # other user.  Merge rules:
    #
    #      * For portals: the resulting portal list is a union of the
    #        portal list for this and the _other_ user.
    #      * For group memberships: group memberships are added from
    #        the _other_ user for all portals which this user doesn't
    #        already have group memberships.  (That is, the group
    #        membership lists for a particular portal are not merged.)
    #        (This rule is to prevent ambiguity if different
    #        authorities have different group hierarchies.  In
    #        practice only one authority is providing authorization
    #        information for a portal, so this shouldn't matter.)
    #      * For all other attributes: an attribute is copied from
    #        _other_ if that attribute is not already set in this
    #        user.
    #
    # Note that these semantics are different from the semantics of
    # `Hash#merge!` in the ruby standard library.
    #
    # @param [Bcsec::User] other the user from which to take attribute
    #   values
    #
    # @return [Bcsec::User] self
    def merge!(other)
      ATTRIBUTES.each do |getter|
        already_set =
          begin
            self.send(getter)
          rescue
            false
          end
        unless already_set
          setter = :"#{getter}="
          value =
            begin
              other.send(getter)
            rescue
              nil # skip inaccessible attributes
            end
          self.send setter, value
        end
      end

      self.default_portal ||= other.default_portal
      self.portals |= other.portals
      other.all_group_memberships.keys.each do |other_portal|
        if self.group_memberships(other_portal).empty?
          self.group_memberships(other_portal).concat(other.group_memberships(other_portal))
        end
      end

      self
    end

    protected

    def required_default_portal
      default_portal or raise "No default portal set.  Please specify one explicitly."
    end
  end
end

