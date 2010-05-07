require 'bcsec/modes'

module Bcsec
  module Modes
    ##
    # Library code shared by modes and their middleware lives here.
    module Support
      autoload :Rfc2617, 'bcsec/modes/support/rfc_2617'
    end
  end
end
