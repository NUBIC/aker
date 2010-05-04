require 'bcsec'

module Bcsec
  module Modes
    ##
    # A noninteractive mode that provides CAS proxy authentication conformant to
    # CAS 2.
    #
    # This mode does _not_ handle interactive CAS authentication; see {Cas} for
    # that.
    #
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
      # The supplied proxy ticket and the {#service_url service URL}.
      #
      # The proxy ticket is received in the HTTP `Authorization`
      # header, per RFC2616.  The scheme must be `CasProxy`.  Example:
      #
      # > `Authorization: CasProxy PT-1272928074r13CBB9ACA794867F3E`
      #
      # @return [Array<String>] the proxy ticket or an empty array
      def credentials
        key = 'HTTP_AUTHORIZATION'
        matches = env[key].match(/CasProxy\s+([SP]T-\S+)/) if env.has_key?(key)

        if matches && matches[1]
          [matches[1], service_url]
        else
          []
        end
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

      ##
      # Builds the service URL for this application.
      #
      # Colloquially, the service URL is the web server URL plus the
      # application mount point.  It does not include anything
      # about the specific resource being requested.  For instance, if
      # you had the resource
      #
      # > https://notis.nubic.northwestern.edu/lsdb/patients/105661
      #
      # which was part of the `/lsdb` application, the service URL
      # would be
      #
      # > https://notis.nubic.northwestern.edu/lsdb
      #
      # A little more formally, the URL is `url scheme +
      # hostname + script name`.  The port is also included if it is
      # not the default for the URL scheme.
      #
      # The service URL never ends with a `/`, even if the application
      # is mounted at the root.
      #
      # @return [String] the service URL derived from the request
      #   environment
      def service_url
        url = "#{env['rack.url_scheme']}://"
        if env['HTTP_HOST']
          url << env['HTTP_HOST'] # includes the port
        else
          url << env['SERVER_NAME']
          default_port = { "http" => "80", "https" => "443" }[env['rack.url_scheme']]
          url << ":#{env["SERVER_PORT"]}" unless env["SERVER_PORT"].to_s == default_port
        end
        url << env["SCRIPT_NAME"]
      end
    end
  end
end
