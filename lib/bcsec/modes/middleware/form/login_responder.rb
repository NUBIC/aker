require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      module Form
        ##
        # Rack middleware used by {Bcsec::Modes::Form} that finishes login
        # requests by rendering a "Login successful" message.
        #
        # This middleware implements half of the form login process.  The
        # other half is implemented by {LoginRenderer}.
        #
        # @author David Yip
        class LoginResponder
          include Support::LoginFormRenderer

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
          # @param assets [#login_html, #login_css] a login asset provider
          def initialize(app, login_path, assets)
            @app = app
            self.login_path = login_path
            self.assets = assets
          end

          ##
          # Rack entry point.  Responds to `POST /login`.
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
              redirect_to_app_root(env)
            end
          end

          def unauthenticated(env)
            request = ::Rack::Request.new(env)

            body = provide_login_html(env, :login_failed => true, :username => request['username'])

            ::Rack::Response.new(body, 401).finish
          end

          def redirect_to_app_root(env)
            ::Rack::Response.new { |resp| resp.redirect(env['SCRIPT_NAME'] + '/') }.finish
          end
        end
      end
    end
  end
end
