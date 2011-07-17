require 'bcsec'

module Bcsec
  ##
  # The namespace for authorities in Bcsec.  The duck-typed meaning of
  # what an authority is is outlined in the documentation for
  # {Bcsec::Authorities::Composite Composite}.
  #
  # Bcsec 2 ships with five authorities:
  #
  # - {Bcsec::Authorities::Netid :netid} verifies usernames and
  #   passwords using NU's central LDAP servers.
  # - {Bcsec::Authorities::Pers :pers} uses the shared `cc_pers`
  #   schema to provide authentication and authorization.  This is the
  #   only built-in authority that is suitable for providing
  #   authorization in production applications.
  # - {Bcsec::Authorities::Cas :cas} provides CAS ticket verification
  #   using a CAS 2 server.
  # - {Bcsec::Authorities::Static :static} provides credential
  #   verification and user authorization based on an in-memory set of
  #   users.  It can be configured in code or by loading a YAML file.
  #   It is intended for integrated tests and application
  #   bootstrapping.
  # - {Bcsec::Authorities::AutomaticAccess :automatic_access} allows
  #   any authenticated user to access your application, even when you
  #   have a portal configured.
  #
  # @see Bcsec::Configuration#authorities=
  module Authorities
    autoload :AutomaticAccess, 'bcsec/authorities/automatic_access'
    autoload :Cas,             'bcsec/authorities/cas'
    autoload :Composite,       'bcsec/authorities/composite'
    autoload :Ldap,            'bcsec/authorities/ldap'
    autoload :Netid,           'bcsec/authorities/netid'
    autoload :Pers,            'bcsec/authorities/pers'
    autoload :Static,          'bcsec/authorities/static'

    autoload :Support,         'bcsec/authorities/support'

    ##
    # The slice that aliases the default authorities.
    # @private
    class Slice < Bcsec::Configuration::Slice
      def initialize
        super do
          alias_authority :automatic_access, Bcsec::Authorities::AutomaticAccess
          alias_authority :cas, Bcsec::Authorities::Cas
          alias_authority :static, Bcsec::Authorities::Static
        end
      end
    end
  end
end

Bcsec::Configuration.add_default_slice(Bcsec::Authorities::Slice.new)
