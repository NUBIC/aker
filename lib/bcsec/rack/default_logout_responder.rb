require 'bcsec'

module Bcsec::Rack
  ##
  # Provides a default response for `GET /logout`.
  class DefaultLogoutResponder
    ##
    # The path at which the middleware will watch for logout requests.
    #
    # @return [String] the logout path
    attr_accessor :logout_path

    ##
    # Instantiates the middleware.
    #
    # @param app [Rack app] the Rack application on which this middleware
    #                       should be layered
    # @param logout_path [String] the logout path
    def initialize(app, logout_path)
      @app = app
      self.logout_path = logout_path
    end

    ##
    # When the path is `/logout`, renders a logout response.
    #
    # @param env [Hash] a Rack environment
    def call(env)
      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == logout_path
        ::Rack::Response.new('You have been logged out.', 200).finish
      else
        @app.call(env)
      end
    end
  end
end
