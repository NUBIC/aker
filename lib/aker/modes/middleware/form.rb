require 'aker'

module Aker::Modes::Middleware
  module Form
    autoload :LogoutResponder,  'aker/modes/middleware/form/logout_responder'
    autoload :LoginRenderer,    'aker/modes/middleware/form/login_renderer'
    autoload :LoginResponder,   'aker/modes/middleware/form/login_responder'
  end
end
