require 'bcsec/cas'

module Bcsec::Cas
  ##
  # A helper for uniform creation of derived attributes for the CAS
  # configuration.  It expects to be mixed in to a context that
  # provides a `configuration` method which returns a
  # {Bcsec::Configuration}.
  #
  # @see Bcsec::Configuration
  module ConfigurationHelper
    ##
    # The login URL on the CAS server.  This may be set explicitly
    # in the configuration as `parameters_for(:cas)[:login_url]`.  If
    # not set explicitly, it will be derived from the base URL.
    def cas_login_url
      configuration.parameters_for(:cas)[:login_url] || File.join(cas_base_url, '/login')
    end

    def cas_base_url
      configuration.parameters_for(:cas)[:base_url]
    end
  end
end
