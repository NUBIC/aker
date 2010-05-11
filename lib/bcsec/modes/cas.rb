require 'bcsec'
require 'rack'

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
      include Bcsec::Cas::ConfigurationHelper
      include ::Rack::Utils
      include Support::AttemptedPath

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas
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

      ##
      # Builds a Rack response that redirects to a CAS server's logout page.
      #
      # @see http://www.jasig.org/cas/protocol
      #      Section 2.3 of the CAS 2 protocol
      #
      # @return [Rack::Response]
      def on_logout
        ::Rack::Response.new { |resp| resp.redirect(cas_logout_url) }
      end

      private

      ##
      # The service URL supplied to the CAS login page.  This is the
      # requested URL, sans any service ticket.
      def service_url
        requested = URI.parse(
          if attempted_path
            url = "#{request.scheme}://#{request.host}"

            unless [ ["https", 443], ["http", 80] ].include?([request.scheme, request.port])
              url << ":#{request.port}"
            end

            url << attempted_path
          else
            request.url
          end
                              )
        if requested.query
          requested.query.gsub!(/(&?)ticket=ST-[^&]+(&?)/) do
            if [$1, $2].uniq == ['&'] # in the middle
              '&'
            else
              nil
            end
          end
          requested.query = nil if requested.query.empty?
        end
        requested.to_s
      end
    end
  end
end
