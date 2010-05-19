require 'bcsec'

module Bcsec
  ##
  # The namespace for authorities in Bcsec.  The duck-typed meaning of
  # what an authority is is outlined in the documentation for
  # {Bcsec::Authorities::Composite Composite}.
  #
  # Bcsec 2 ships with four authorities:
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
  #   It is intended for integrated tests and application bootstrapping.
  #
  # @see Bcsec::Configuration#authorities=
  module Authorities
    autoload :Cas,       'bcsec/authorities/cas'
    autoload :Composite, 'bcsec/authorities/composite'
    autoload :Netid,     'bcsec/authorities/netid'
    autoload :Pers,      'bcsec/authorities/pers'
    autoload :Static,    'bcsec/authorities/static'

    autoload :Support,   'bcsec/authorities/support'
  end
end
