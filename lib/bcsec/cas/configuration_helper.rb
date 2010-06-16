require 'bcsec/cas'
require 'uri'

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
    #
    # @return [String]
    def cas_login_url
      configuration.parameters_for(:cas)[:login_url] || URI.join(cas_base_url, 'login').to_s
    end

    ##
    # The logout URL on the CAS server.  This may be set explicitly
    # in the configuration as `parameters_for(:cas)[:logout_url]`.  If
    # not set explicitly, it will be derived from the base URL.
    #
    # @return [String]
    def cas_logout_url
      configuration.parameters_for(:cas)[:logout_url] || URI.join(cas_base_url, 'logout').to_s
    end

    ##
    # The base URL for all not-otherwise-explicitly-specified URLs on
    # the CAS server.  It may be set in the CAS parameters as either
    # `:base_url` (preferred) or `:cas_base_url` (for backwards
    # compatibility with bcsec 1.x).
    #
    # The base URL should end in a `/` (forward slash).  If it does not, a
    # trailing forward slash will be appended.
    #
    # @see http://www.ietf.org/rfc/rfc1808.txt
    #   RFC 1808, sections 4 and 5
    # @return [String, nil]
    def cas_base_url
      appending_forward_slash do
        configuration.parameters_for(:cas)[:base_url] ||
          configuration.parameters_for(:cas)[:cas_base_url]
      end
    end

    ##
    # The URL that CAS will provide the PGT and PGTIOU to, per section
    # 2.5.4 of the spec.  Some CAS servers require that this be an
    # SSL-protected resource.  It is set in the CAS parameters as
    # `:proxy_callback_url`.
    #
    # @return [String, nil]
    def cas_proxy_callback_url
      configuration.parameters_for(:cas)[:proxy_callback_url]
    end

    ##
    # The URL that the CAS client can retrieve the PGT from once it
    # has been deposited at the {#cas_proxy_callback_url} by the CAS
    # server.  It is set in the CAS parameters as
    # `:proxy_retrieval_url`.
    #
    # (Note that this is not part of the CAS protocol &mdash; it is
    # rubycas-client specific.)
    #
    # @return [String, nil]
    def cas_proxy_retrieval_url
      configuration.parameters_for(:cas)[:proxy_retrieval_url]
    end

    private

    def appending_forward_slash
      url = yield

      (url && url[-1].chr != '/') ? url + '/' : url
    end
  end
end
