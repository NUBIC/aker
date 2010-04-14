require 'bcsec'

module Bcsec
  module Modes
    ##
    # A noninteractive mode that provides CAS proxy authentication conformant to CAS 2.
    # This authenticator uses RubyCAS-Client.
    #
    # This mode does _not_ handle interactive CAS authentication; see {Cas} for that.
    #
    # @see http://github.com/gunark/rubycas-client
    #      RubyCAS-Client at Github
    # @see http://www.jasig.org/cas/protocol
    #      CAS 2 protocol specification
    #
    # @author David Yip
    class CasProxy < Bcsec::Modes::Base
      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas_proxy
      end

      ##
      # Authenticates a proxy ticket.
      #
      # If authentication is successful, then success! (from
      # Warden::Strategies::Base) is called with a Bcsec::User object.  If
      # authentication fails, then nothing is done.
      #
      # @return [nil]
      def authenticate!
        user = authority.valid_credentials?(self.class.key, proxy_ticket)
        success!(user) if user
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client failing noninteractive authentication.
      #
      # @return [String]
      def scheme
        "CasProxy"
      end

      ##
      # Returns true if a proxy ticket is present, false otherwise.
      def valid?
        !proxy_ticket.nil?
      end

      ##
      # The supplied proxy ticket.
      #
      # The proxy ticket is assumed to be a parameter named PT in either GET
      # or POST data.
      def proxy_ticket
        request['PT']
      end
    end
  end
end
