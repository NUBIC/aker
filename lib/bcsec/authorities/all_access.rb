require 'bcsec/authorities'

module Bcsec
  module Authorities
    ##
    # An authority which permits any user access to any portal.  This
    # effectively bypasses the portal check part of the bcsec
    # authorization process.  It's useful in situations where an
    # application wants to allow in, say, anyone with a netid:
    #
    #     Bcsec.configure {
    #       authorities :netid, :all_access
    #     }
    class AllAccess
      # Creates a new instance.  `AllAccess` does not read any
      # configuration properties.
      def initialize(ignored)
      end

      ##
      # Always allows access.
      # @return [true]
      def may_access?(user, portal)
        true
      end
    end
  end
end
