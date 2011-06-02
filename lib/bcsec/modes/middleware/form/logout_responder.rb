require 'bcsec'

module Bcsec::Modes::Middleware::Form
  class LogoutResponder
    include Bcsec::Modes::Support::LoginFormAssetProvider

    ##
    # Bcsec configuration data.  This is usually set by the form mode.
    #
    # @return [Bcsec::Configuration]
    attr_accessor :configuration

    def initialize(app, configuration)
      @app = app
      self.configuration = configuration
    end

    ##
    # When given `GET /logout` without the `:using_custom_logout_page` `:form`
    # parameter set, builds a Rack response containing the login form with a
    # "you have been logged out" notification.  Otherwise, passes the response
    # on.
    #
    # @return a finished Rack response
    def call(env)
      return @app.call(env) if using_custom_logout_page?

      if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == '/logout'
        ::Rack::Response.new(login_html(env, :logged_out => true)).finish
      else
        @app.call(env)
      end
    end

    private

    ##
    # Whether a custom logout page is in use.
    #
    # @return [Boolean]
    def using_custom_logout_page?
      configuration.parameters_for(:form)[:use_custom_logout_page]
    end
  end
end
