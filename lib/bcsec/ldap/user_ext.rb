require 'bcsec/ldap'

module Bcsec::Ldap
  ##
  # Extensions to {Bcsec::User} for users that were found in
  # an LDAP server.
  #
  # @see Bcsec::Authorities::Ldap
  module UserExt
    ##
    # A hash of all the attributes in the user's ldap
    # record. The keys are downcased versions of the
    # (case-insensitive) LDAP keys.  Values are arrays of strings
    # (since LDAP allows multiple instances of the same key).
    #
    # @return [Hash<Symbol, Array<String>>]
    attr_accessor :ldap_attributes
  end
end
