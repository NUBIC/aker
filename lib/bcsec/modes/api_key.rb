module Bcsec
  module Modes
    ##
    # A noninteractive mode that provides API key authentication.
    #
    # This mode expects to find a WWW-Authenticate header that looks like
    #
    #     ApiKey challenge
    #
    # where _challenge_ is the API key.
    class ApiKey < Base
      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :api_key
      end

      ##
      # Returns true if an API key challenge is present, false otherwise.
      def valid?
        env['HTTP_WWW_AUTHENTICATE'] =~ /#{challenge} [^\n]+/
      end

      ##
      # Used to build a WWW-Authenticate header that will be returned to a
      # client failing noninteractive authentication.
      #
      # @return [String]
      def challenge
        'ApiKey'
      end
    end
  end
end
