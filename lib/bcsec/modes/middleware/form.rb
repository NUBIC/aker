require 'bcsec'

module Bcsec
  module Modes
    module Middleware
      module Form
        autoload :LoginRenderer,  'bcsec/modes/middleware/form/login_renderer'
        autoload :LoginResponder, 'bcsec/modes/middleware/form/login_responder'
      end
    end
  end
end
