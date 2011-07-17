require 'aker'

module Aker::Cas::Middleware
  autoload :LogoutResponder, 'aker/cas/middleware/logout_responder'
  autoload :TicketRemover,   'aker/cas/middleware/ticket_remover'
end
