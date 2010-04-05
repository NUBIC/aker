require 'bcsec'

module Bcsec
  module Authorities
    autoload :AllAccess, 'bcsec/authorities/all_access'
    autoload :Netid,     'bcsec/authorities/netid'
    autoload :Static,    'bcsec/authorities/static'
  end
end
