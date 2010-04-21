require 'bcsec'

module Bcsec
  module Modes
    ##
    # A noninteractive mode that provides CAS proxy authentication conformant to
    # CAS 2.  This authenticator uses RubyCAS-Client.
    #
    # This mode does _not_ handle interactive CAS authentication; see {Cas} for
    # that.
    #
    # @see http://github.com/gunark/rubycas-client
    #      RubyCAS-Client at Github
    # @see http://www.jasig.org/cas/protocol
    #      CAS 2 protocol specification
    #
    # @author David Yip
    class CasProxy < Bcsec::Modes::Base
      include Rfc2617

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas_proxy
      end

      ##
      # The type of credentials supplied by this mode.
      #
      # @return [Symbol]
      def kind
        self.class.key
      end

      ##
      # The supplied proxy ticket.
      #
      # The proxy ticket is assumed to be a parameter named PT in either GET
      # or POST data.
      #
      # @return [Array<String>] the proxy ticket or an empty array
      def credentials
        [request['PT']].compact
      end

      ##
      # Returns true if a proxy ticket is present, false otherwise.
      def valid?
        !credentials.empty?
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client failing noninteractive authentication.
      #
      # @return [String]
      def scheme
        "CasProxy"
      end
    end
  end
end
