require 'bcsec/authorities'

require 'casclient'

module Bcsec::Authorities
  ##
  # An authority which verifies CAS tickets with an actual CAS server.
  class Cas
    include Bcsec::Cas::ConfigurationHelper
    attr_reader :configuration

    ##
    # @private exposed for testing
    # @return CASClient::Client
    attr_accessor :client

    ##
    # Creates a new instance of this authority.  It reads parameters
    # from the `:cas` parameters section of the given configuration.
    # See {Bcsec::Cas::ConfigurationHelper} for information about the
    # meanings of these parameters.
    def initialize(configuration)
      @configuration = configuration
      unless cas_base_url
        raise ":base_url parameter is required for CAS"
      end
      @client = CASClient::Client.new(:cas_base_url => cas_base_url)
    end

    def valid_credentials?(kind, *credentials)
      return :unsupported unless kind == :cas

      ticket, service = credentials
      st = client.validate_service_ticket(CASClient::ServiceTicket.new(ticket, service))

      if st.response.is_failure?
        nil
      else
        Bcsec::User.new(st.response.user)
      end
    end
  end
end
