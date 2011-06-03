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
    include Support::LoginFormAssetProvider

    ##
    # The path at which the middleware will watch for login requests.
    # @return [String] the login path
    attr_accessor :login_path

    ##
    # Bcsec configuration data.  This is usually set by the form mode.
    #
    # @return [Configuration]
    attr_accessor :configuration

    ##
    # Instantiates the middleware.
    #
    # @param app [Rack app] the Rack application on which this middleware
    #                       should be layered
    # @param login_path [String] the login path
    # @param configuration [Configuration] Bcsec configuration
    def initialize(app, login_path, configuration)
      @app = app
      self.configuration = configuration
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
      request = ::Rack::Request.new(env)

      if !warden.authenticated?
        warden.custom_failure!
        unauthenticated(request)
      else
        redirect_to_target(request)
      end
    end

    def unauthenticated(request)
      if using_custom_login_page?
        return @app.call(request.env.merge('bcsec.login_failed' => true))
      end

      body = login_html(request.env,
                        :login_failed => true,
                        :username => request['username'],
                        :url => request['url'])

      ::Rack::Response.new(body, 401).finish
    end

    def redirect_to_target(request)
      target = !(request['url'].blank?) ? request['url'] : request.env['SCRIPT_NAME'] + '/'

      ::Rack::Response.new { |resp| resp.redirect(target) }.finish
    end

    def using_custom_login_page?
      configuration.parameters_for(:form)[:use_custom_login_page]
    end
  end
end
