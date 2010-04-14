require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      autoload :Form, 'bcsec/modes/middleware/form'
      autoload :FormAssetProvider, 'bcsec/modes/middleware/form_asset_provider'
    end
  end
end
