require 'bcsec'

module Bcsec
  ##
  # The namespace for authorities in Bcsec.  The duck-typed meaning of
  # what an authority is is outlined in the documentation for
  # {Bcsec::Authorities::Composite Composite}.
  #
  # @see Bcsec::Configuration#authorities=
  module Authorities
    autoload :Cas,       'bcsec/authorities/cas'
    autoload :Composite, 'bcsec/authorities/composite'
    autoload :Netid,     'bcsec/authorities/netid'
    autoload :Pers,      'bcsec/authorities/pers'
    autoload :Static,    'bcsec/authorities/static'
  end
end
