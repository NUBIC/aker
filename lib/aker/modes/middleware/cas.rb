require 'aker'

module Aker::Modes::Middleware::Cas
  autoload :LogoutResponder,  'aker/modes/middleware/cas/logout_responder'
  autoload :TicketRemover,    'aker/modes/middleware/cas/ticket_remover'
end
