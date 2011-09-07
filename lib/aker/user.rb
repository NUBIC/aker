require 'aker'

module Aker
  ##
  # @private
  module DeprecatedUser
    [:nu_employee_id, :personnel_id].each do |deprec_id|
      define_method deprec_id do
        Deprecation.notify(
          "#{deprec_id} is deprecated. Use identifiers[#{deprec_id.inspect}] instead.", "3.0")
        identifiers[deprec_id]
      end

      define_method "#{deprec_id}=" do |value|
        Deprecation.notify(
          "#{deprec_id} is deprecated. Use identifiers[#{deprec_id.inspect}] instead.", "3.0")
        identifiers[deprec_id] = value
      end
    end
  end

  class User
    include DeprecatedUser

    ATTRIBUTES = :username, :first_name, :middle_name, :last_name,
      :title, :business_phone, :fax, :email, :address, :city, :state, :country

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
    # @param [#to_sym,nil] portal the portal in question.  If nil,
    #   uses {#default_portal}.
    # @return [Boolean] true if the user has access, otherwise false.
    def may_access?(portal=nil)
      portals.include?((portal || required_default_portal).to_sym)
    end

    ##
    # @overload permit?(*groups, options={})
    #   Determines whether this user has access to any of the given
    #   groups.
    #   @param [Array<#to_sym>] groups the names of the groups to query
    #   @param [Hash] options additional constraints on the query
    #   @option options [#to_sym] :portal (#default_portal) the portal
    #     within which to do the group check
    #   @option options [Array] :affiliate_ids ([]) Affiliate ids constraining group membership
    #   @return [Boolean]
    #
    # @overload permit?(*groups, options={}, &block)
    #   Evaluates the given block if the user is in any of the given
    #   groups.
    #   @param [Array<#to_sym>] groups the names of the groups to use
    #     as the condition
    #   @param [Hash] options additional constraints on the condition
    #   @option options [#to_sym] :portal (#default_portal) the portal
    #     within which to do the group check
    #   @option options [Array] :affiliate_ids ([]) Affiliate ids constraining group membership
    #   @return [Object,nil] the value of the block if it is
    #     executed; otherwise nil
    def permit?(*args)
      options = args.last.is_a?(Hash) ? args.pop : { }
      portal = options[:portal] || default_portal
      affiliate_ids = options[:affiliate_ids] || []

      permitted =
        if args.empty?
          may_access?(portal)
        else
          args.detect { |group| group_memberships(portal).include?(group.to_sym, *affiliate_ids) }
        end

      if block_given?
        permitted ? yield : nil
      else
        permitted
      end
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
    # A mapping of identifers that apply to this user. The values that
    # might be set in this hash are defined by authorities.
    #
    # @since 2.2.0
    # @return [Hash<Symbol, Object>] the identifiers for this user.
    def identifiers
      @identifiers ||= {}
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
    # * For portals: the resulting portal list is a union of the
    #   portal list for this and the _other_ user.
    # * For group memberships: group memberships are added from
    #   the _other_ user for all portals which this user doesn't
    #   already have group memberships.  (That is, the group
    #   membership lists for a particular portal are not merged.)
    #   This rule is to prevent ambiguity if different
    #   authorities have different group hierarchies.  In
    #   practice only one authority is providing authorization
    #   information for a portal, so this shouldn't matter.
    # * For identifiers: any identifier in the _other_ user that is
    #   not already set in this user is copied over.
    # * For all other attributes: an attribute is copied from
    #   _other_ if that attribute is not already set in this
    #   user.
    #
    # Note that these semantics are different from the semantics of
    # `Hash#merge!` in the ruby standard library.
    #
    # @param [Aker::User] other the user from which to take attribute
    #   values
    #
    # @return [Aker::User] self
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
      other.identifiers.each do |ident, value|
        identifiers[ident] ||= value
      end

      self
    end

    protected

    def required_default_portal
      default_portal or raise "No default portal set.  Please specify one explicitly."
    end
  end
end

