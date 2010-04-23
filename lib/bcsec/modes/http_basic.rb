require 'bcsec'
require 'base64'

module Bcsec
  module Modes
    ##
    # A noninteractive and interactive mode that provides HTTP Basic
    # authentication.
    #
    # This mode operates noninteractively when an Authorization header with a
    # Basic challenge is present.  It operates interactively when it is
    # configured as an interactive authentication mode.
    #
    # @see http://www.ietf.org/rfc/rfc2617.txt
    #      RFC 2617
    # @author David Yip
    class HttpBasic < Bcsec::Modes::Base
      include Rfc2617

      ##
      # Recognizes valid Basic challenges.
      #
      # An HTTP Basic challenge is the word "Basic", followed by one space,
      # followed by a Base64-encoded string.
      #
      # @see http://www.ietf.org/rfc/rfc2045.txt
      #      RFC 2045, section 6.8
      BasicPattern = %r{^Basic ((?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?)$}

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :http_basic
      end

      ##
      # The type of credentials supplied by this mode.
      #
      # @return [Symbol]
      def kind
        :user
      end

      # Decodes and extracts a (username, password) pair from an Authorization
      # header.
      #
      # This method checks if the format of the Authorization header is a valid
      # response to a Basic challenge.  If it is, then a username (and possibly
      # a password) are returned.  If it is not, then an empty array is
      # returned.
      #
      # @return [Array<String>] username and password, username, or an empty
      #                         array
      #
      # @see BasicPattern
      # @see http://www.ietf.org/rfc/rfc2617.txt
      #      RFC 2617, section 2
      def credentials
        key = 'HTTP_AUTHORIZATION'
        matches = env[key].match(BasicPattern) if env.has_key?(key)

        if matches && matches[1]
          Base64.decode64(matches[1]).split(':', 2)
        else
          []
        end
      end

      ##
      # Returns true if a valid Basic challenge is present, false otherwise.
      def valid?
        credentials.length == 2
      end

      ##
      # Builds a Rack response with status 401 that indicates a need for
      # authentication.
      #
      # With Web browsers, this will cause a username/password dialog to
      # appear.
      #
      # @return [Rack::Response]
      def on_ui_failure
        ::Rack::Response.new([], 401, {'WWW-Authenticate' => challenge})
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client when authentication is required.
      #
      # @see HttpMode#challenge
      # @return [String]
      def scheme
        "Basic"
      end
    end
  end
end
