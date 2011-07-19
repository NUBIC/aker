require 'aker'
require 'uri'
require 'rack'

module Aker
  module Form
    ##
    # An interactive mode that accepts a username and password POSTed from an
    # HTML form.
    #
    # It expects the username in a `username` parameter and the unobfuscated
    # password in a `password` parameter.
    #
    # By default, the form is rendered at and the credentials are
    # received on '/login'; this can be overridden in the
    # configuration like so:
    #
    #     Aker.configure {
    #       rack_parameters :login_path => '/log-in-here'
    #     }
    #
    # This mode also renders said HTML form if authentication
    # fails. Rendering is handled by by {Middleware::LoginRenderer}.
    #
    # @author David Yip
    class Mode < Aker::Modes::Base
      include ::Rack::Utils
      include Aker::Modes::Support::AttemptedPath

      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :form
      end

      ##
      # Appends the {Middleware::LoginResponder login responder} to its
      # position in the Rack middleware stack.
      def self.append_middleware(builder)
        builder.use(Middleware::LoginResponder)
        builder.use(Middleware::LogoutResponder)
      end

      ##
      # Prepends the {Middleware::LoginRenderer login form renderer} to
      # its position in the Rack middleware stack.
      def self.prepend_middleware(builder)
        builder.use(Middleware::LoginRenderer)
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
        uri.path = env['SCRIPT_NAME'] + login_path(configuration)
        uri.to_s
      end

      ##
      # Builds a Rack response that redirects to the login form.
      #
      # @return [Rack::Response]
      def on_ui_failure
        ::Rack::Response.new do |resp|
          resp.redirect(login_url + '?url=' + escape(attempted_path))
        end
      end

      ##
      # The path at which the login form will be accessible, as
      # configured in the specified context.
      #
      # This path is specified relative to the application's mount point.  If
      # you're looking for the absolute URL of the login form, you need to use
      # {#login_url}.
      #
      # @param [Aker::Configuration] configuration the configuration
      #   from which to derive the login path.
      #
      # @return [String]
      def login_path(configuration)
        configuration.parameters_for(:rack)[:login_path]
      end
      private :login_path
    end
  end
end
