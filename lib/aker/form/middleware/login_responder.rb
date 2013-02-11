require 'aker'

module Aker::Form::Middleware
  ##
  # Rack middleware used by {Aker::Form::Mode} that finishes login
  # requests by rendering a "Login successful" message.
  #
  # This middleware implements half of the form login process.  The
  # other half is implemented by {LoginRenderer}.
  #
  # @author David Yip
  class LoginResponder
    include Aker::Form::HtmlResponse
    include Aker::Form::LoginFormAssetProvider
    include Aker::Rack::ConfigurationHelper

    ##
    # Instantiates the middleware.
    #
    # @param app [Rack app] the Rack application on which this middleware
    #                       should be layered
    def initialize(app)
      @app = app
    end

    ##
    # Rack entry point.  Responds to a `POST` to the configured login
    # path.
    #
    # If the user is authenticated and a URL is given in the `url`
    # parameter, then this action will redirect to `url`.
    #
    # @param env the Rack environment
    # @return a finished Rack response
    def call(env)
      case [env['REQUEST_METHOD'], env['PATH_INFO']]
        when ['POST', login_path(env)]; respond(env)
        else @app.call(env)
      end
    end

    protected

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
      request = Rack::Request.new(env)
      body = login_html(env,
                        :login_failed => true,
                        :username => request['username'],
                        :url => request['url'])

      html_response(body, 401).finish
    end

    def redirect_to_target(env)
      request = Rack::Request.new(env)
      target = !(request['url'].blank?) ? request['url'] : request.env['SCRIPT_NAME'] + '/'

      html_response { |resp| resp.redirect(target) }.finish
    end
  end
end
