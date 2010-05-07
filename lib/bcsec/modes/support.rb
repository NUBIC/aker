require 'bcsec/modes'

module Bcsec
  module Modes
    ##
    # Library code shared by modes and their middleware lives here.
    module Support
      autoload :LoginFormAssetProvider, 'bcsec/modes/support/login_form_asset_provider'
      autoload :LoginFormRenderer,      'bcsec/modes/support/login_form_renderer'
      autoload :Rfc2617,                'bcsec/modes/support/rfc_2617'
    end
  end
end
