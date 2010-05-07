require 'bcsec'
require 'uri'

module Bcsec
  module Modes
    ##
    # An interactive mode that accepts a username and password POSTed from an
    # HTML form.
    #
    # It expects the username in a `username` parameter and the unobfuscated
    # password in a `password` parameter.
    #
    # This mode also renders said HTML form if authentication fails.  This is
    # provided by {Middleware::Form::LoginRenderer}.
    #
    # @author David Yip
    class Form < Bcsec::Modes::Base
      include Support::LoginFormRenderer

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :form
      end

      ##
      # The path at which the login form will be accessible.  Currently
      # hard-wired as `/login`.
      #
      # This path is specified relative to the application's mount point.  If
      # you're looking for the absolute URL of the login form, you need to use
      # login_url.
      #
      # @return [String] `/login`
      def self.login_path
        '/login'
      end

      ##
      # The login form asset provider used by this middleware.
      #
      # @return [Support::LoginFormAssetProvider]
      def self.assets
        Support::LoginFormAssetProvider.new
      end

      ##
      # Appends the {Middleware::Form::LoginResponder login responder} to its
      # position in the Rack middleware stack.
      def self.append_middleware(builder)
        builder.use(Middleware::Form::LoginResponder, login_path, assets)
      end

      ##
      # Prepends the {Middleware::Form::LoginRenderer login form renderer} to
      # its position in the Rack middleware stack.
      def self.prepend_middleware(builder)
        builder.use(Middleware::Form::LoginRenderer, login_path, assets)
      end

      def initialize(env, scope=nil)
        super
        self.assets = self.class.assets
      end

      ##
      # The type of credentials supplied by this mode.
      #
      # @return [Symbol]
      def kind
        :user
      end

      ##
      # Extracts username and password from request parameters.
      #
      # @return [Array<String>] username and password, username (if password
      #                         missing), or an empty array
      def credentials
        [request['username'], request['password']].compact
      end

      ##
      # Returns true if username and password are present, false otherwise.
      def valid?
        credentials.length == 2
      end

      ##
      # The absolute URL for the login form.
      #
      # @return [String]
      def login_url
        uri = URI.parse(request.url)
        uri.path = env['SCRIPT_NAME'] + self.class.login_path
        uri.to_s
      end

      ##
      # Builds a Rack response that redirects to the login form.
      #
      # @return [Rack::Response]
      def on_ui_failure
        ::Rack::Response.new { |resp| resp.redirect(login_url) }
      end

      ##
      # Builds a Rack response containing the login form with a "you have been
      # logged out" notification.
      #
      # @return [Rack::Response]
      def on_logout
        body = provide_login_html(env, :logged_out => true)

        ::Rack::Response.new(body, 200)
      end
    end
  end
end
