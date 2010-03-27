require 'bcsec'

module Bcsec
  module Authorities
    autoload :AllAccess, 'bcsec/authorities/all_access'
    autoload :Static, 'bcsec/authorities/static'
  end
end
