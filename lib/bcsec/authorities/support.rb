require 'bcsec/authorities'

module Bcsec::Authorities
  ##
  # Library code shared by authorities lives here.
  module Support
    autoload :FindSoleUser, 'bcsec/authorities/support/find_sole_user'
  end
end
