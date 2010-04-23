require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      ##
      # Rack middleware used by {Bcsec::Modes::Form} to render an HTML login
      # form.
      #
      # @author David Yip
      class Form
        ##
        # The form asset provider used by an instance of this middleware.
        #
        # @see Middleware::FormAssetProvider
        # @return [#login_html, #login_css] a login asset provider
        attr_accessor :assets

        ##
        # The path at which the middleware will watch for login requests.
        # @return [String] the login path
        attr_accessor :login_path

        ##
        # Instantiates the middleware.
        #
        # @param app [Rack app] The Rack application on which this middleware should be layered.
        # @param assets [#login_html, #login_css] a login asset provider
        # @param login_path [String] the login path
        def initialize(app, login_path, assets)
          @app = app
          self.login_path = login_path
          self.assets = assets
        end

        ##
        # Rack entry point.
        #
        # `call` returns one of three responses, depending on the path.
        #
        # * If the path is `login_path`, `call` returns an HTML form for
        #   submitting a username and password.
        # * If the path is `login_path + "/login.css"`, `call` returns the CSS
        #   for the aforementioned form.
        # * If the path is anything else, `call` passes the request down
        #   through the Rack stack.
        #
        # @return a finished Rack response
        def call(env)
          case env['PATH_INFO']
            when login_path;                provide_login_html(env)
            when login_path + '/login.css'; provide_login_css
            else                            @app.call(env)
          end
        end

        private

        ##
        # An HTML form for logging in.
        #
        # @param env the Rack environment
        # @return a finished Rack response
        def provide_login_html(env)
          ::Rack::Response.new(assets.login_html(env)).finish
        end

        ##
        # CSS for the form provided by {provide_login_html}.
        #
        # @param env the Rack environment
        # @return a finished Rack response
        def provide_login_css
          ::Rack::Response.new(assets.login_css) do |resp|
            resp['Content-Type'] = 'text/css'
          end.finish
        end
      end
    end
  end
end
