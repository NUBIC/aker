require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      module Form
        autoload :AssetProvider, 'bcsec/modes/middleware/form/asset_provider'
        autoload :LoginRenderer, 'bcsec/modes/middleware/form/login_renderer'
      end
    end
  end
end
