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
          attr_accessor :login_path

          attr_accessor :assets

          ##
          # Instantiates the middleware.
          #
          # @param app [Rack app] The Rack application on which this middleware should be layered.
          # @param login_path [String] the login path
          # @param assets [#login_html, #login_css] a login asset provider
          def initialize(app, login_path, assets)
            @app = app
            self.login_path = login_path
            self.assets = assets
          end

          def call(env)
            case [env['REQUEST_METHOD'], env['PATH_INFO']]
              when ['POST', login_path]; render_login_response(env)
              else @app.call(env)
            end
          end

          private

          def render_login_response(env)
            warden = env['warden']

            if !warden.authenticated?
              warden.custom_failure!
              render_unauthenticated_response(env)
            else
              redirect_to_app_root(env)
            end
          end

          def render_unauthenticated_response(env)
            ::Rack::Response.new(assets.login_html(env, :show_failure => true)) do |resp|
              resp.status = 401
            end.finish
          end
          
          def redirect_to_app_root(env)
            ::Rack::Response.new { |resp| resp.redirect(env['SCRIPT_NAME'] + '/') }.finish
          end
        end
      end
    end
  end
end
