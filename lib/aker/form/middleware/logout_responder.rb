require 'aker'

module Aker::Form::Middleware
  class LogoutResponder
    include Aker::Form::LoginFormAssetProvider
    include Aker::Rack::ConfigurationHelper

    def initialize(app)
      @app = app
    end

    ##
    # When given `GET /logout` builds a Rack response containing the
    # login form with a "you have been logged out" notification.
    # Otherwise, passes the response on.
    #
    # @return a finished Rack response
    def call(env)
      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/logout'
        ::Rack::Response.new(login_html(env, :logged_out => true)).finish
      else
        @app.call(env)
      end
    end
  end
end
