require 'bcsec'
require 'warden'

module Bcsec
  module Modes
    ##
    # Base class for all authentication modes.
    #
    # An _authentication mode_ is an an object that implements an
    # authentication protocol. Modes may be _interactive_, meaning that they
    # require input from a human, and/or _noninteractive_, meaning that they
    # can be used without user intervention.
    #
    # For mode implementors: It is not strictly necessary to implement bcsec
    # authentication modes as subclasses of `Bcsec::Modes::Base`.  However, keep
    # in mind the following:
    #
    # * Your mode must at some point in its inheritance hierarchy subclass
    #   `Warden::Strategies::Base`, because that's what bcsec uses internally to
    #   implement authentication, and Warden actually checks subtyping.
    #   `Bcsec::Modes::Base` sets up the inheritance hierarchy for you.
    # * `Bcsec::Modes::Base` implements functionality shared across modes.
    #
    # @author David Yip
    # @see
    #  http://github.com/hassox/warden/blob/v0.10.3/lib/warden/strategies/base.rb
    #  `Warden::Strategies::Base` at hassox:warden@v0.10.3
    # @see
    #  http://github.com/hassox/warden/blob/v0.10.3/lib/warden/strategies.rb#L14-16
    #  `Warden::Strategies` at hassox:warden@v0.10.3
    class Base < Warden::Strategies::Base
      ##
      # Returns parameters for a mode.
      #
      # Internally, this method pulls parameters from a {Bcsec::Configuration}
      # object in the `bcsec.configuration` Rack environment variable.
      #
      # This method is guaranteed to always return a hash.
      #
      # @see Bcsec::Configuration
      # @return [Hash]
      def parameters_for(mode)
        env['bcsec.configuration'].parameters_for(mode)
      end
    end
  end
end
