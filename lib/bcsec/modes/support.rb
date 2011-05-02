require 'bcsec/modes'

module Bcsec
  module Modes
    ##
    # Library code shared by modes and their middleware lives here.
    module Support
      autoload :AttemptedPath,          'bcsec/modes/support/attempted_path'
      autoload :LoginFormAssetProvider, 'bcsec/modes/support/login_form_asset_provider'
      autoload :Rfc2617,                'bcsec/modes/support/rfc_2617'
    end
  end
end
