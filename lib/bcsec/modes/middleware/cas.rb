require 'bcsec'

module Bcsec::Modes::Middleware::Cas
  autoload :LogoutResponder,  'bcsec/modes/middleware/cas/logout_responder'
  autoload :TicketRemover,    'bcsec/modes/middleware/cas/ticket_remover'
end
