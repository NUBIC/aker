require 'bcsec/cas'

require 'castanet'

module Bcsec::Cas
  ##
  # Extensions for {Bcsec::User} instances that come from CAS
  # credentials.
  #
  # @see Bcsec::Authorities::Cas
  module UserExt
    include Castanet::Client

    ##
    # The base URL of the CAS server.
    #
    # This is typically set by {Bcsec::Authorities::Cas#valid_credentials?}.
    #
    # @see Bcsec::Cas::ConfigurationHelper#cas_url
    # @return [String]
    attr_accessor :cas_url

    ##
    # The proxy callback URL used by the CAS server.
    #
    # This is typically set by {Bcsec::Authorities::Cas#valid_credentials?}.
    #
    # @see Bcsec::Cas::ConfigurationHelper#proxy_callback_url
    # @return [String, nil]
    attr_accessor :proxy_callback_url

    ##
    # The proxy retrieval URL from which Bcsec will retrieve PGTs.
    #
    # This is typically set by {Bcsec::Authorities::Cas#valid_credentials?}.
    #
    # @see Bcsec::Cas::ConfigurationHelper#proxy_retrieval_url
    # @return [String, nil]
    attr_accessor :proxy_retrieval_url

    ##
    # The proxy granting ticket associated with the {Bcsec::User}, or nil if no
    # PGT exists.
    #
    # @return [String, nil]
    attr_accessor :pgt

    ##
    # Returns a proxy ticket so that an application may authenticate
    # to another CAS-using service on behalf of this user.  Each
    # invocation will request and return a fresh ticket.
    #
    # @param [String] service_base_url the URL by which CAS knows the
    #   service that this proxy will be used for.  For bcsec-protected
    #   applications, this will always be the base URL for the whole
    #   application &mdash; i.e., the URL for the server plus the mount
    #   point for the application, if any.
    #
    # @see Bcsec::Modes::CasProxy#service_url
    #
    # @return [String] a new ticket
    def cas_proxy_ticket(service_base_url)
      issue_proxy_ticket(pgt, service_base_url).ticket
    end
  end
end
