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
    # This mode also renders said HTML form (which is expected to be provided
    # by another piece of Rack middleware) if authentication fails.
    #
    # @author David Yip
    class Form < Bcsec::Modes::Base
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
      # Prepends the {Middleware::Form login form renderer} to its position in
      # the Rack middleware stack.
      def self.prepend_middleware(builder)
        builder.use Middleware, login_path
      end

      ##
      # Authenticates a (username, password) pair.
      #
      # If authentication is successful, then success! (from
      # Warden::Strategies::Base) is called with a Bcsec::User object.  If
      # authentication fails, then nothing is done.
      #
      # @return [nil]
      def authenticate!
        user = authority.valid_credentials?(:user, *credentials)
        success!(user) if user
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
      def on_ui_failure(env)
        Rack::Response.new { |resp| resp.redirect(login_url) }
      end

      ##
      # Returns true if username and password are present, false otherwise.
      def valid?
        credentials.length == 2
      end

      private

      ##
      # Extracts username and password from request parameters.
      def credentials
        [request['username'], request['password']].compact
      end

      class Middleware
      end
    end
  end
end
