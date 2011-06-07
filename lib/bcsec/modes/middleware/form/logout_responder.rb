require 'bcsec'

module Bcsec::Modes::Middleware::Form
  class LogoutResponder
    include Bcsec::Modes::Support::LoginFormAssetProvider
    include Bcsec::Rack::ConfigurationHelper

    def initialize(app)
      @app = app
    end

    ##
    # When given `GET /logout` without the `:using_custom_logout_page` `:form`
    # parameter set, builds a Rack response containing the login form with a
    # "you have been logged out" notification.  Otherwise, passes the response
    # on.
    #
    # @return a finished Rack response
    def call(env)
      return @app.call(env) if using_custom_logout_page?(env)

      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/logout'
        ::Rack::Response.new(login_html(env, :logged_out => true)).finish
      else
        @app.call(env)
      end
    end
  end
end
