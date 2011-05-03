require 'bcsec'

module Bcsec::Modes::Middleware::Form
  class LogoutResponder
    include Bcsec::Modes::Support::LoginFormRenderer

    def initialize(app, assets)
      @app = app

      self.assets = assets
    end

    def call(env)
      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/logout'
        provide_logout_html(env)
      else
        @app.call(env)
      end
    end

    private

    ##
    # Builds a Rack response containing the login form with a "you have been
    # logged out" notification.
    #
    # @return a finished Rack response
    def provide_logout_html(env)
      ::Rack::Response.new(assets.login_html(env, :logged_out => true)).finish
    end
  end
end
