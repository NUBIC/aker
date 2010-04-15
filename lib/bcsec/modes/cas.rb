require 'bcsec'

module Bcsec
  module Modes
    ##
    # An interactive mode that provides CAS authentication conformant to CAS 2.
    # This authenticator uses RubyCAS-Client.
    #
    # This mode does _not_ handle noninteractive CAS proxying.  See {CasProxy}
    # for that.
    #
    # @see http://github.com/gunark/rubycas-client
    #      RubyCAS-Client at Github
    # @see http://www.jasig.org/cas/protocol
    #      CAS 2 protocol specification
    #
    # @author David Yip
    class Cas < Bcsec::Modes::Base
      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas
      end

      ##
      # The login URL on the CAS server.
      def cas_login_url
        parameters_for(:cas)[:login_url]
      end

      ##
      # The type of credentials supplied by this mode.
      #
      # @return [Symbol]
      def kind
        self.class.key
      end

      ##
      # Extracts the service ticket from the request parameters.
      #
      # The service ticket is assumed to be a parameter named ST in either GET
      # or POST data.
      #
      # @return [Array<String>] service ticket or an empty array if no service
      #                         ticket found
      def credentials
        [request['ST']].compact
      end

      ##
      # Returns true if a service ticket is present in the query string, false
      # otherwise.
      def valid?
        !credentials.empty?
      end

      ##
      # Builds a Rack response that redirects to a CAS server's login page.
      #
      # The constructed response uses the URL of the resource for which
      # authentication failed as the CAS service URL.
      #
      # @see http://www.jasig.org/cas/protocol
      #      Section 2.2.1 of the CAS 2 protocol
      #
      # @return [Rack::Response]
      def on_ui_failure(env)
        Rack::Response.new do |resp|
          login_uri = URI.parse(cas_login_url)
          login_uri.query = "service=#{service_url(env)}"
          resp.redirect(login_uri.to_s)
        end
      end

      private

      ##
      # The service URL supplied to the CAS login page.  This is currently the
      # URL of the requested resource.
      def service_url(env)
        request.url
      end
    end
  end
end
