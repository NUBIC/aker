require 'aker'
require 'rack'

module Aker
  module Cas
    ##
    # An interactive mode that provides CAS authentication conformant to CAS 2.
    #
    # This mode does _not_ handle non-interactive CAS proxying.  See
    # {ProxyMode} for that.
    #
    # @see http://www.jasig.org/cas/protocol
    #      CAS 2 protocol specification
    #
    # @author David Yip
    class ServiceMode < Aker::Modes::Base
      include ConfigurationHelper
      include ::Rack::Utils
      include Aker::Modes::Support::AttemptedPath
      include ServiceUrl

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas
      end

      ##
      # Appends the {Middleware::LogoutResponder logout responder} and
      # the {Middleware::TicketRemover ticket remover} to the Rack
      # middleware stack.
      def self.append_middleware(builder)
        builder.use(Middleware::LogoutResponder)
        builder.use(Middleware::TicketRemover)
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
      # @return [Array<String>,nil] a two-item array containing the
      #   service ticket and the service URL to which the ticket
      #   (it is asserted) applies
      def credentials
        if request['ticket']
          [request['ticket'], service_url]
        end
      end

      ##
      # Returns true if a service ticket is present in the query string, false
      # otherwise.
      def valid?
        credentials
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
      def on_ui_failure
        ::Rack::Response.new do |resp|
          login_uri = URI.parse(cas_login_url)
          login_uri.query = "service=#{escape(service_url)}"
          resp.redirect(login_uri.to_s)
        end
      end
    end
  end
end
