require 'bcsec'

module Bcsec
  ##
  # The authority-independent representation of a user's association
  # with a particular group, possibly constrained by affiliate.
  class GroupMembership
    ##
    # The affiliate IDs to which this membership is scoped.  If this
    # array is blank or nil, the membership applies to all affiliates.
    attr_accessor :affiliate_ids

    ##
    # Create a new instance.
    #
    # @param [Group] group the group for which this object records
    #   membership
    def initialize(group)
      @group = group
    end

    ##
    # Determines whether this membership applies to the given
    # affiliate.
    #
    # @return [Boolean]
    def include_affiliate?(affiliate_id)
      affiliate_ids.blank? ? true : affiliate_ids.include?(affiliate_id.to_i)
    end

    ##
    # @return [String] the name of the group for which this object
    #   indicates membership.
    def group_name
      self.group.name
    end

    ##
    # @return [Group] the group for which this is a membership
    def group
      @group
    end

    def affiliate_ids
      @affiliate_ids ||= []
    end
  end

  ##
  # An authority-independent collection of all the group memberships
  # for a particular user at a particular portal.
  class GroupMemberships < Array
    ##
    # The portal for which all these group memberships apply.
    #
    # @return [Symbol]
    attr_reader :portal

    ##
    # Create a new instance.
    #
    # @param [#to_sym] portal
    def initialize(portal)
      @portal = portal.to_sym
    end

    ##
    # Determines whether this collection indicates that the user is
    # authorized in the the given group, possibly constrained by one
    # or more affiliates.
    #
    # (Note that this method hides the superclass `include?` method.)
    #
    # @param [Group,#to_s] group the group in question or its name
    # @param [Array<Fixnum>,nil] *affiliate_ids the affiliates to use to
    #   constrain the query.
    #
    # @return [Boolean] true so long as the user is authorized in
    #   `group` for **at least one** of the specified affiliates.  If
    #   no affiliates are specified, only the groups themselves are
    #   considered.
    def include?(group, *affiliate_ids)
      !find(group, *affiliate_ids).empty?
    end

    ##
    # Finds the group memberships that match the given group, possibly
    # constrained by one or more affiliates.
    #
    # (Note that this method hides the `Enumerable` method `find`.
    # You can still use it under its `detect` alias.)
    #
    # @param [Group,#to_s] group the group in question or its name
    # @param [Array<Fixnum>,nil] *affiliate_ids the affiliates to use to
    #   constrain the query.
    #
    # @return [Array<GroupMembership>]
    def find(group, *affiliate_ids)
      candidates = self.select { |gm| gm.group.include?(group) }
      return candidates if affiliate_ids.empty?
      candidates.select { |gm| affiliate_ids.detect { |id| gm.include_affiliate?(id) } }
    end
  end
end
