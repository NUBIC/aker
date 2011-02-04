require 'bcsec/authorities'

require 'castanet'

module Bcsec::Authorities
  ##
  # An authority which verifies CAS tickets with an actual CAS server.
  #
  # @see Bcsec::Cas::CasUser
  class Cas
    include Bcsec::Cas::ConfigurationHelper
    include Castanet::Client

    attr_reader :configuration

    ##
    # Creates a new instance of this authority.  It reads parameters
    # from the `:cas` parameters section of the given configuration.
    # See {Bcsec::Cas::ConfigurationHelper} for information about the
    # meanings of these parameters.
    def initialize(configuration)
      @configuration = configuration

      unless cas_url
        raise ":base_url parameter is required for CAS"
      end
    end

    ##
    # Verifies the given credentials with the CAS server.  The `:cas`
    # and `:cas_proxy` kinds are supported.  Both kinds require two
    # credentials in the following order:
    #
    # * The ticket (either a service ticket or proxy ticket)
    # * The service URL associated with the ticket
    #
    # The returned user will be extended with {Bcsec::Cas::CasUser}.
    #
    # If CAS proxying is enabled, then this method also retrieves the
    # proxy-granting ticket for the user.
    #
    # @see http://www.jasig.org/cas/protocol
    #   CAS 2 protocol specification, section 2.5.4
    # @return [Bcsec::User,:unsupported,nil] a user if the credentials
    #   are valid, `:unsupported` if the kind is anything but `:cas`
    #   or `:cas_proxy`, and nil otherwise
    def valid_credentials?(kind, *credentials)
      return :unsupported unless [:cas, :cas_proxy].include?(kind)

      ticket = ticket_for(kind, *credentials)
      ticket.present!

      return nil unless ticket.ok?

      Bcsec::User.new(ticket.username).tap do |u|
        u.extend Bcsec::Cas::CasUser

        u.cas_url = cas_url
        u.proxy_callback_url = proxy_callback_url
        u.proxy_retrieval_url = proxy_retrieval_url

        if ticket.pgt_iou
          ticket.retrieve_pgt!

          u.pgt = ticket.pgt
        end
      end
    end

    private

    def ticket_for(kind, ticket, service)
      case kind
      when :cas; service_ticket(ticket, service)
      when :cas_proxy; proxy_ticket(ticket, service)
      end
    end
  end
end
