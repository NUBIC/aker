require 'bcsec'

module Bcsec
  module Authorities
    autoload :AllAccess, 'bcsec/authorities/all_access'
    autoload :Composite, 'bcsec/authorities/composite'
    autoload :Netid,     'bcsec/authorities/netid'
    autoload :Pers,      'bcsec/authorities/pers'
    autoload :Static,    'bcsec/authorities/static'
  end
end
