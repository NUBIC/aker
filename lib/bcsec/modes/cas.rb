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
      # The login URL on the CAS server.
      attr_accessor :cas_login_url

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas
      end

      ##
      # Authenticates a service ticket.
      #
      # If authentication is successful, then success! (from
      # Warden::Strategies::Base) is called with a {User} object.  If
      # authentication fails, then nothing is done.
      #
      # @return [nil]
      def authenticate!
        user = authority.valid_credentials?(self.class.key, service_ticket)
        success!(user) if user
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

      ##
      # Returns true if a service ticket is present in the query string, false
      # otherwise.
      def valid?
        !service_ticket.nil?
      end

      private

      ##
      # Extracts the service ticket from the request parameters.
      #
      # The service ticket is assumed to be a parameter named ST in either GET
      # or POST data.
      def service_ticket
        request.params['ST']
      end

      ##
      # The service URL supplied to the CAS login page.  This is currently the
      # URL of the requested resource.
      def service_url(env)
        URI::Generic.build(:scheme => env['rack.url_scheme'],
                           :host => env['HTTP_HOST'] || env['SERVER_NAME'],
                           :port => env['SERVER_PORT'],
                           :path => env['PATH_INFO']).to_s
      end
    end
  end
end
