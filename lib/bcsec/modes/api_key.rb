require 'bcsec'

module Bcsec
  module Modes
    ##
    # A noninteractive mode that provides API key authentication.
    #
    # This mode expects the client to supply an Authorization header that looks
    # like
    #
    #     ApiKey response
    #
    # where _response_ is the API key.
    #
    # Responses must consist of one or more characters from the printable
    # ASCII set sans whitespace, i.e. ASCII [0x21, 0x7E].
    #
    # @author David Yip
    class ApiKey < Base
      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :api_key
      end

      ##
      # Authenticates an API key.
      #
      # If authentication is successful, then success! (from
      # Warden::Strategies::Base) is called with a Bcsec::User object.  If
      # authentication fails, then nothing is done.
      #
      # @return [nil]
      def authenticate!
        user = authority.valid_credentials?(self.class.key, api_key)
        success!(user) if user
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client failing noninteractive authentication.
      #
      # @return [String]
      def scheme
        'ApiKey'
      end

      ##
      # Returns true if an API key is present, false otherwise.
      def valid?
        !api_key.nil?
      end

      private

      ##
      # Extracts a key from an Authorization header issued in response to an
      # API key challenge.
      def api_key
        authorization = env['HTTP_AUTHORIZATION']

        if authorization
          match = authorization.match(/#{scheme} ([\x21-\x7E]+)/)
          match[1] if match
        end
      end
    end
  end
end
