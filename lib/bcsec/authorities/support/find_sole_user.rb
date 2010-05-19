require 'bcsec/authorities/support'

module Bcsec::Authorities::Support
  ##
  # Provides a singular version of the `find_users` authority method.
  # Authorities which implement that method can mix this in to get
  # `find_user` for free.
  module FindSoleUser
    ##
    # Finds the sole user which meets the given criteria.  If more
    # than one user meets the criteria, no users are returned.
    #
    # @see Bcsec::Authorities::Composite#find_users
    # @return [Bcsec::User,nil] the sole matching user or `nil`
    def find_user(criteria)
      result = find_users(criteria)
      if result.size == 1
        result.first
      else
        nil
      end
    end
  end
end
