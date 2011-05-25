require 'bcsec'

module Bcsec
  module Rack
    ##
    # Middleware for ending authenticated sessions.  This middleware listens for
    # `GET /logout` requests, and when such requests are received, clears user
    # data.
    #
    # ## Implications of GET
    #
    # `GET` was chosen to ensure that there always exists a way to clear
    # application session data independent of whether it is possible to get to a
    # logout link.  (If unmarshalable data exists in the session -- say, stored
    # objects whose format has changed between application revisions -- it is
    # possible to get into a state where logout links cannot be accessed.)
    #
    # Using `GET` does mean that it is possible to execute CSRF attacks that
    # will log out the user.  The severity of this can range from a minor
    # annoyance (just having to log in again while browsing a series of pages)
    # to major (losing all data in a large POST).
    #
    # @see Bcsec::Rack.use_in
    #
    # @author David Yip
    class Logout
      ##
      # The path at which the middleware will watch for logout requests.
      #
      # @return [String] the logout path
      attr_accessor :logout_path

      ##
      # Instantiates the middleware.
      #
      # @param app [Rack app] the Rack application on which this middleware
      #                       should be layered
      # @param logout_path [String] the logout path
      def initialize(app, logout_path)
        @app = app
        self.logout_path = logout_path
      end

      ##
      # When given `GET /logout`, invokes Warden's logout procedure (which
      # resets the session), and passes control down to the rest of the
      # application.
      #
      # If the application does not provide a handler for `/logout`, then
      # the handler defined by {DefaultLogoutResponder} will be invoked.
      #
      # @see Bcsec::Rack.use_in
      # @param env [Hash] a Rack environment
      # @return [Array] a finished Rack response
      def call(env)
        if env['REQUEST_METHOD'] == 'GET' && env['PATH_INFO'] == logout_path
          env['warden'].logout
        end

        @app.call(env)
      end
    end
  end
end
