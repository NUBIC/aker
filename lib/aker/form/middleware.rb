require 'aker'

module Aker::Form
  module Middleware
    autoload :LogoutResponder,  'aker/form/middleware/logout_responder'
    autoload :LoginRenderer,    'aker/form/middleware/login_renderer'
    autoload :LoginResponder,   'aker/form/middleware/login_responder'
  end
end
