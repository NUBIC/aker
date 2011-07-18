require 'aker'
require 'warden'

module Aker
  module Modes
    ##
    # Base class for all authentication modes.
    #
    # An _authentication mode_ is an an object that implements an
    # authentication protocol. Modes may be _interactive_, meaning that they
    # require input from a human, and/or _non-interactive_, meaning that they
    # can be used without user intervention.
    #
    # For mode implementors: While it is not strictly necessary to implement
    # aker modes as subclasses of `Aker::Modes::Base`, it is recommended that
    # you do so.
    #
    # @author David Yip
    class Base < Warden::Strategies::Base
      include Aker::Rack::EnvironmentHelper

      ##
      # Exposes the configuration this mode should use.
      #
      # @return [Aker::Configuration]
      def configuration
        super(env)
      end

      ##
      # Exposes the authority this mode will use to validate
      # credentials.  Internally it is extracted from the
      # `aker.authority` Rack environment variable.
      #
      # @return [Object]
      def authority
        super(env)
      end

      ##
      # Whether or not the current request is interactive.
      #
      # @return [Boolean]
      def interactive?
        super(env)
      end

      ##
      # Used by Warden to determine whether or not it should store user
      # information in the session.  In Aker, this is computed as the result
      # of {#interactive?}.
      #
      # N.B. The `!!` is present because Warden requires that this method return
      # `false` (not `false` or `nil`) for session serialization to be disabled.
      #
      # @see
      #   http://rubydoc.info/gems/warden/1.0.3/Warden/Strategies/Base#store%3F-instance_method
      #   Warden::Strategies::Base#store documentation
      # @see
      #   https://github.com/hassox/warden/blob/v1.0.3/lib/warden/proxy.rb#L158
      #   Warden's expectations for this method
      #
      # @return [Boolean]
      def store?
        !!interactive?
      end

      ##
      # Authenticates a user.
      #
      # {#authenticate!} expects `kind` and `credentials` to be
      # defined.  See subclasses for examples.
      #
      # If authentication is successful, then success! (from
      # `Warden::Strategies::Base`) is called with a {User} object.
      # If authentication fails, then nothing is done.
      #
      # @return [void]
      def authenticate!
        user = authority.valid_credentials?(kind, *credentials)
        success!(user) if user
      end
    end
  end
end
