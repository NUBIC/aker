require 'bcsec/authorities'

require 'casclient'

module Bcsec::Authorities
  ##
  # An authority which verifies CAS tickets with an actual CAS server.
  #
  # @see http://github.com/gunark/rubycas-client
  #      RubyCAS-Client at Github
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
      @client = CASClient::Client.new(:cas_base_url => cas_base_url,
                                      :proxy_callback_url => cas_proxy_callback_url,
                                      :proxy_retrieval_url => cas_proxy_retrieval_url)
    end

    ##
    # Verifies the given credentials with the CAS server.  The `:cas`
    # and `:cas_proxy` kinds are supported.  Both kinds require two
    # credentials:
    #
    # * The ticket (either a service ticket or proxy ticket)
    # * The service URL associated with the ticket
    #
    # The returned user will be extended with {Bcsec::Cas::CasUser}.
    #
    # @return [Bcsec::User,:unsupported,nil] a user if the credentials
    #   are valid, `:unsupported` if the kind is anything but `:cas`
    #   or `:cas_proxy`, and nil otherwise
    def valid_credentials?(kind, *credentials)
      return :unsupported unless [:cas, :cas_proxy].include?(kind)

      ticket, service = credentials
      st = case kind
           when :cas
             client.validate_service_ticket(CASClient::ServiceTicket.new(ticket, service))
           when :cas_proxy
             client.validate_proxy_ticket(CASClient::ProxyTicket.new(ticket, service))
           end

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
