require 'aker'

module Aker::Rack
  ##
  # Provides a default response for `GET` of the application's
  # configured logout path.
  class DefaultLogoutResponder
    include ConfigurationHelper

    ##
    # Instantiates the middleware.
    #
    # @param app [Rack app] the Rack application on which this middleware
    #                       should be layered
    def initialize(app)
      @app = app
    end

    ##
    # When the path is the configured logout path, renders a logout
    # response.
    #
    # @param env [Hash] a Rack environment
    def call(env)
      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == logout_path(env)
        ::Rack::Response.new('You have been logged out.', 200).finish
      else
        @app.call(env)
      end
    end
  end
end
