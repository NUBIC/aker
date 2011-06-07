require 'bcsec'

module Bcsec::Modes::Middleware
  module Form
    autoload :LogoutResponder,  'bcsec/modes/middleware/form/logout_responder'
    autoload :LoginRenderer,    'bcsec/modes/middleware/form/login_renderer'
    autoload :LoginResponder,   'bcsec/modes/middleware/form/login_responder'
  end
end
