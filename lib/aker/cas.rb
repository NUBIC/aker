require 'aker'

module Aker
  ##
  # Common code for dealing with CAS servers.
  module Cas
    autoload :Authority,           'aker/cas/authority'
    autoload :ConfigurationHelper, 'aker/cas/configuration_helper'
    autoload :Middleware,          'aker/cas/middleware'
    autoload :ProxyMode,           'aker/cas/proxy_mode'
    autoload :RackProxyCallback,   'aker/cas/rack_proxy_callback'
    autoload :ServiceMode,         'aker/cas/service_mode'
    autoload :ServiceUrl,          'aker/cas/service_url'
    autoload :UserExt,             'aker/cas/user_ext'

    ##
    # @private
    class Slice < Aker::Configuration::Slice
      def initialize
        super do
          alias_authority :cas, Authority

          register_mode ProxyMode
          register_mode ServiceMode
        end
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Cas::Slice.new)
