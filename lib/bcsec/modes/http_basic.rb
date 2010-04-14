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
      # The authentication realm to be used in challenges.
      attr_accessor :realm

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :http_basic
      end

      ##
      # Authenticates a (username, password) pair.
      #
      # If authentication is successful, then success! (from
      # Warden::Strategies::Base) is called with a Bcsec::User object.  If
      # authentication fails, then nothing is done.
      #
      # @return [nil]
      def authenticate!
        user = authority.valid_credentials?(:user, *credentials)
        success!(user) if user
      end

      ##
      # Builds a Rack response with status 401 that indicates a need for
      # authentication.
      #
      # With Web browsers, this will cause a username/password dialog to
      # appear.
      #
      # @return [Rack::Response]
      def on_ui_failure(env)
        Rack::Response.new([], 401, {'WWW-Authenticate' => scheme})
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client failing noninteractive authentication.
      #
      # @return [String]
      def scheme
        %Q{Basic realm="#{realm}"}
      end

      ##
      # Returns true if a valid Basic challenge is present, false otherwise.
      def valid?
        env['HTTP_AUTHORIZATION'] =~ BasicPattern
      end

      private

      ##
      # Decodes and extracts a (username, password) pair from a Basic challenge.
      #
      # @return [Array<String>] username and password, or an empty array if the
      #         encoded credentials do not conform to the Basic Authentication
      #         Scheme
      #
      # @see http://www.ietf.org/rfc/rfc2617.txt
      #      RFC 2617, section 2
      def credentials
        encoded_credentials = env['HTTP_AUTHORIZATION'].match(BasicPattern)

        if encoded_credentials && encoded_credentials[1]
          Base64.decode64(encoded_credentials[1]).split(':', 2)
        else
          []
        end
      end
    end
  end
end
