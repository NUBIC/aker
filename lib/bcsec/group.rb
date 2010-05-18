require 'tree'

require 'bcsec'

module Bcsec
  ##
  # The authority-independent representation of a group.
  #
  # @see http://rubytree.rubyforge.org/rdoc/Tree/TreeNode.html
  class Group < Tree::TreeNode
    ##
    # Creates a new group with the given name.  You can add children
    # using `<<`.
    #
    # @param [#to_s] name the desired name
    # @param [Array,nil] args additional arguments.  Included for
    #   marshalling compatibility with the base class.
    def initialize(name, *args)
      super # overridden to attach docs
    end

    ##
    # Determines whether this group or any of its children matches the
    # given parameter for authorization purposes.
    #
    # @param [#to_s,Group] other the thing to compare this
    #   group to
    # @return [Boolean] true if the name of this group or any of its
    #   children is a case-insensitive match for the other.
    def include?(other)
      other_name =
        case other
        when Group; other.name;
        else other.to_s;
        end
      self.find { |g| g.name.downcase == other_name.downcase }
    end
  end
end
