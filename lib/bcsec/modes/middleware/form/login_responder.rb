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
          include Support::LoginFormAssetProvider

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
            request = ::Rack::Request.new(env)

            if !warden.authenticated?
              warden.custom_failure!
              unauthenticated(request)
            else
              redirect_to_target(request)
            end.finish
          end

          def unauthenticated(request)
            body = login_html(request.env,
                              :login_failed => true,
                              :username => request['username'],
                              :url => request['url'])

            ::Rack::Response.new(body, 401)
          end

          def redirect_to_target(request)
            target = !(request['url'].blank?) ? request['url'] : request.env['SCRIPT_NAME'] + '/'

            ::Rack::Response.new { |resp| resp.redirect(target) }
          end
        end
      end
    end
  end
end
