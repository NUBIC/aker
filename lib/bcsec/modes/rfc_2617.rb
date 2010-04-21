require 'bcsec/modes'

module Bcsec::Modes
  ##
  # A mixin providing common methods for modes which implement
  # authentication according to RFC 2616 and RFC 2617.
  module Rfc2617
    ##
    # Builds the content of the WWW-Authenticate challenge header for
    # a particular mode.  Requires that the target mode implement
    # `#scheme`.
    #
    # @return [String] the challenge
    def challenge
      "#{scheme} realm=\"#{realm}\""
    end

    ##
    # Determines the value to use for the required "realm" challenge
    # parameter.  If set, the {Bcsec::Configuration#portal portal} is
    # used.  Otherwise "Bcsec" is used.
    #
    # @return [String]
    def realm
      (configuration.portal? ? configuration.portal : 'Bcsec').to_s
    end
  end
end
