require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      module Form
        ##
        # Rack middleware used by {Bcsec::Modes::Form} to render an HTML login
        # form.
        #
        # This middleware implements half of the form login process.  The
        # other half is implemented by {LoginResponder}.
        #
        # @author David Yip
        class LoginRenderer
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
          # @param app [Rack app] The Rack application on which this middleware
          #   should be layered.
          # @param login_path [String] the login path
          # @param configuration [Configuration] Bcsec configuration
          def initialize(app, login_path, configuration)
            @app = app
            self.configuration = configuration
            self.login_path = login_path
          end

          ##
          # Rack entry point.
          #
          # `call` returns one of four responses, depending on the path,
          # method, and whether or not `:use_custom_login_page` is set in the
          # `:form` configuration parameter group.
          #
          # * If `:use_custom_login_page` is truthy, `call` passes the request
          #   down through the Rack stack.
          # * If the method is GET and the path is `login_path`, `call` returns
          #   an HTML form for submitting a username and password.
          # * If the method is GET and the path is `login_path + "/login.css"`,
          #   `call` returns the CSS for the aforementioned form.
          # * Otherwise, `call` passes the request down through the Rack stack.
          #
          # @return a finished Rack response
          def call(env)
            return @app.call(env) if using_custom_login_page?

            case [env['REQUEST_METHOD'], env['PATH_INFO']]
              when ['GET', login_path];                provide_login_html(env)
              when ['GET', login_path + '/login.css']; provide_login_css
              else                                     @app.call(env)
            end
          end

          private

          ##
          # An HTML form for logging in.
          #
          # @param env the Rack environment
          # @return a finished Rack response
          def provide_login_html(env)
            request = ::Rack::Request.new(env)

            ::Rack::Response.new(login_html(env, :url => request['url'])).finish
          end

          ##
          # CSS for the form provided by {provide_login_html}.
          #
          # @return a finished Rack response
          def provide_login_css
            ::Rack::Response.new(login_css) do |resp|
              resp['Content-Type'] = 'text/css'
            end.finish
          end

          ##
          # Whether a custom login page will be provided by the application.
          #
          # @return [Boolean]
          def using_custom_login_page?
            configuration.parameters_for(:form)[:use_custom_login_page]
          end
        end
      end
    end
  end
end
