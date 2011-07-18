require 'aker'

module Aker
  ##
  # The namespace for authorities in Aker.  The duck-typed meaning of
  # what an authority is is outlined in the documentation for
  # {Aker::Authorities::Composite Composite}.
  #
  # Aker 2 ships with five authorities:
  #
  # - {Aker::Authorities::Netid :netid} verifies usernames and
  #   passwords using NU's central LDAP servers.
  # - {Aker::Authorities::Pers :pers} uses the shared `cc_pers`
  #   schema to provide authentication and authorization.  This is the
  #   only built-in authority that is suitable for providing
  #   authorization in production applications.
  # - {Aker::Authorities::Cas :cas} provides CAS ticket verification
  #   using a CAS 2 server.
  # - {Aker::Authorities::Static :static} provides credential
  #   verification and user authorization based on an in-memory set of
  #   users.  It can be configured in code or by loading a YAML file.
  #   It is intended for integrated tests and application
  #   bootstrapping.
  # - {Aker::Authorities::AutomaticAccess :automatic_access} allows
  #   any authenticated user to access your application, even when you
  #   have a portal configured.
  #
  # @see Aker::Configuration#authorities=
  module Authorities
    autoload :AutomaticAccess, 'aker/authorities/automatic_access'
    autoload :Cas,             'aker/authorities/cas'
    autoload :Composite,       'aker/authorities/composite'
    autoload :Ldap,            'aker/authorities/ldap'
    autoload :Netid,           'aker/authorities/netid'
    autoload :Pers,            'aker/authorities/pers'
    autoload :Static,          'aker/authorities/static'

    autoload :Support,         'aker/authorities/support'

    ##
    # The slice that aliases the default authorities.
    # @private
    class Slice < Aker::Configuration::Slice
      def initialize
        super do
          alias_authority :automatic_access, Aker::Authorities::AutomaticAccess
          alias_authority :cas, Aker::Authorities::Cas
          alias_authority :static, Aker::Authorities::Static
        end
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Authorities::Slice.new)
