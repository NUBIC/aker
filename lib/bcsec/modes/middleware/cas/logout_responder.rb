require 'bcsec'

module Bcsec::Modes::Middleware::Cas
  class LogoutResponder
    include Bcsec::Cas::ConfigurationHelper

    ##
    # Bcsec configuration data.  This is usually set by the CAS mode.
    #
    # @return [Bcsec::Configuration]
    attr_accessor :configuration

    ##
    # @param app a Rack app
    # @param [String] cas_logout_url the CAS logout URL
    def initialize(app, configuration)
      @app = app
      self.configuration = configuration
    end

    ##
    # Rack entry point.
    #
    # Given `GET /logout`, redirects to {#cas_logout_url}.  All other requests
    # are passed through.
    #
    # @see http://www.jasig.org/cas/protocol
    #      Section 2.3 of the CAS 2 protocol
    def call(env)
      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/logout'
        ::Rack::Response.new { |r| r.redirect(cas_logout_url) }.finish
      else
        @app.call(env)
      end
    end
  end
end
