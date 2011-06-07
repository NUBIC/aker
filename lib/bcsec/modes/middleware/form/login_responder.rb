require 'bcsec'

module Bcsec::Modes::Middleware::Form
  ##
  # Rack middleware used by {Bcsec::Modes::Form} that finishes login
  # requests by rendering a "Login successful" message.
  #
  # This middleware implements half of the form login process.  The
  # other half is implemented by {LoginRenderer}.
  #
  # @author David Yip
  class LoginResponder
    include Bcsec::Modes::Support::LoginFormAssetProvider
    include Bcsec::Rack::ConfigurationHelper

    ##
    # The path at which the middleware will watch for login requests.
    # @return [String] the login path
    attr_accessor :login_path

    ##
    # Instantiates the middleware.
    #
    # @param app [Rack app] the Rack application on which this middleware
    #                       should be layered
    # @param login_path [String] the login path
    def initialize(app, login_path)
      @app = app
      self.login_path = login_path
    end

    ##
    # Rack entry point.  Responds to `POST /login`.
    #
    # If the user is authenticated and a URL is given in the `url`
    # parameter, then this action will redirect to `url`.
    #
    # @param env the Rack environment
    # @return a finished Rack response
    def call(env)
      case [env['REQUEST_METHOD'], env['PATH_INFO']]
        when ['POST', login_path]; respond(env)
        else @app.call(env)
      end
    end

    private

    def respond(env)
      warden = env['warden']

      if !warden.authenticated?
        warden.custom_failure!
        unauthenticated(env)
      else
        redirect_to_target(env)
      end
    end

    def unauthenticated(env)
      if using_custom_login_page?(env)
        return @app.call(env.merge('bcsec.login_failed' => true))
      end

      request = Rack::Request.new(env)
      body = login_html(env,
                        :login_failed => true,
                        :username => request['username'],
                        :url => request['url'])

      ::Rack::Response.new(body, 401).finish
    end

    def redirect_to_target(env)
      request = Rack::Request.new(env)
      target = !(request['url'].blank?) ? request['url'] : request.env['SCRIPT_NAME'] + '/'

      ::Rack::Response.new { |resp| resp.redirect(target) }.finish
    end
  end
end
