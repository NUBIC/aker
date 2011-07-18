require 'aker'

module Aker
  ##
  # Common code for dealing with CAS servers.
  #
  # @see Aker::Modes::Cas
  # @see Aker::Authorities::Cas
  module Cas
    autoload :UserExt,             'aker/cas/user_ext'
    autoload :ConfigurationHelper, 'aker/cas/configuration_helper'
    autoload :RackProxyCallback,   'aker/cas/rack_proxy_callback'
    autoload :ServiceUrl,          'aker/cas/service_url'
  end
end
