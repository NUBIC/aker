require 'bcsec/authorities'

require 'casclient'

module Bcsec::Authorities
  ##
  # An authority which verifies CAS tickets with an actual CAS server.
  #
  # @see Bcsec::Cas::CasUser
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

    ##
    # Verifies the given credentials with the CAS server.
    #
    # The returned user will be extended with {Bcsec::Cas::CasUser}.
    #
    # @return [Bcsec::User,:unsupported,nil] a user if the credentials
    #   are valid, `:unsupported` if the kind is anything but `:cas`
    #   or `:cas_proxy`, and nil otherwise
    def valid_credentials?(kind, *credentials)
      return :unsupported unless kind == :cas

      ticket, service = credentials
      st = client.validate_service_ticket(CASClient::ServiceTicket.new(ticket, service))

      if st.response.is_failure?
        nil
      else
        Bcsec::User.new(st.response.user).tap do |u|
          u.extend Bcsec::Cas::CasUser
          u.init_cas_user :client => @client, :pgt_iou => st.response.pgt_iou
        end
      end
    end
  end
end
