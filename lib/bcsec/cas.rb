require 'bcsec'

module Bcsec
  ##
  # Common code for dealing with CAS servers.
  #
  # @see Bcsec::Modes::Cas
  # @see Bcsec::Authorities::Cas
  module Cas
    autoload :CasUser,             'bcsec/cas/cas_user'
    autoload :ConfigurationHelper, 'bcsec/cas/configuration_helper'
    autoload :RackProxyCallback,   'bcsec/cas/rack_proxy_callback'
  end
end