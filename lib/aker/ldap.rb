require 'aker'

module Aker
  ##
  # Namespace for LDAP-related functionality in Aker.
  module Ldap
    autoload :Authority, 'aker/ldap/authority'
    autoload :UserExt,   'aker/ldap/user_ext'

    ##
    # @private
    class Slice < Aker::Configuration::Slice
      def initialize
        super do
          alias_authority :ldap, Authority
        end
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Ldap::Slice.new)
