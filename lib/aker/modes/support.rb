require 'aker/modes'

module Aker
  module Modes
    ##
    # Library code shared by modes and their middleware lives here.
    module Support
      autoload :AttemptedPath,          'aker/modes/support/attempted_path'
      autoload :LoginFormAssetProvider, 'aker/modes/support/login_form_asset_provider'
      autoload :Rfc2617,                'aker/modes/support/rfc_2617'
    end
  end
end
