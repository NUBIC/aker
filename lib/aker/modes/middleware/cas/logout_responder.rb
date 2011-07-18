require 'aker'

module Aker::Modes::Middleware::Cas
  class LogoutResponder
    include Aker::Rack::ConfigurationHelper

    ##
    # @param app a Rack app
    # @param [String] cas_logout_url the CAS logout URL
    def initialize(app)
      @app = app
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
        ::Rack::Response.new { |r| r.redirect(cas_logout_url(env)) }.finish
      else
        @app.call(env)
      end
    end

    private

    def cas_logout_url(env)
      configuration(env).parameters_for(:cas)[:logout_url] || URI.join(cas_url(env), 'logout').to_s
    end

    def cas_url(env)
      appending_forward_slash do
        configuration(env).parameters_for(:cas)[:base_url] ||
          configuration(env).parameters_for(:cas)[:cas_base_url]
      end
    end

    def appending_forward_slash
      url = yield

      (url && url[-1].chr != '/') ? url + '/' : url
    end
  end
end
