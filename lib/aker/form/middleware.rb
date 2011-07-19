require 'aker'

module Aker::Form
  module Middleware
    autoload :CustomViewLoginResponder, 'aker/form/middleware/custom_view_login_responder'
    autoload :LogoutResponder,          'aker/form/middleware/logout_responder'
    autoload :LoginRenderer,            'aker/form/middleware/login_renderer'
    autoload :LoginResponder,           'aker/form/middleware/login_responder'
  end
end
