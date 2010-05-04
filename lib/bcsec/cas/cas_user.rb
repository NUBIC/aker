require 'bcsec/cas'
require 'casclient'

module Bcsec::Cas
  ##
  # Extensions for {Bcsec::User} instances that come from CAS
  # credentials.
  #
  # @see Bcsec::Authorities::Cas
  module CasUser
    ##
    # The method that the CAS authority uses to inject the necessary
    # parameters into the user after extending it.
    #
    # @private not part of the public API, but must be visible to the
    #   CAS authority.
    # @return [void]
    def init_cas_user(cas_attributes={})
      @cas_client = cas_attributes[:client]
      @cas_pgt_iou = cas_attributes[:pgt_iou]
    end

    ##
    # Returns a proxy ticket so that an application may authenticate
    # to another CAS-using service on behalf of this user.  Each
    # invocation will request and return a fresh ticket.
    #
    # Internal detail:  the CAS proxy-granting ticket will not be
    # requested until the first time this method is invoked.
    #
    # @param [String] service_base_url the URL by which CAS knows the
    #   service that this proxy will be used for.  For bcsec-protected
    #   applications, this will always be the base URL for the whole
    #   application -- i.e., the URL for the server plus the mount
    #   point for the application, if any.
    #
    # @return [String] a new ticket
    def cas_proxy_ticket(service_base_url)
      @cas_client.request_proxy_ticket(cas_pgt, service_base_url).ticket
    end

    private

    def cas_pgt
      @cas_pgt ||=
        begin
          unless @cas_client.proxy_retrieval_url
            # This is necessary because rubycas-client doesn't
            # validate it itself, leading to an inscrutable error if
            # it isn't present.
            raise "Cannot retrieve a CAS proxy ticket without a proxy retrieval URL"
          end
          @cas_client.retrieve_proxy_granting_ticket(@cas_pgt_iou)
        end
    end
  end
end
