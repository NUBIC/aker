require 'bcsec'

module Bcsec::Modes::Middleware::Cas
  ##
  # Middleware which issues a redirect immediately after CAS
  # authentication succeeds so that users never see a URL with the
  # ticket in it. This prevents them from, e.g., bookmarking a URL
  # with a ticket in it, keeping things cleaner and preventing
  # requests to the CAS server for tickets which are definitely
  # expired.
  class TicketRemover
    def initialize(app)
      @app = app
    end

    def call(env)
      if authenticated?(env) && ticket_present?(env)
        url = Bcsec::Cas::ServiceUrl.service_url(Rack::Request.new(env))
        [301, { 'Location' => url }, ["Removing authenticated CAS ticket"] ]
      else
        @app.call(env)
      end
    end

    private

    def authenticated?(env)
      env['bcsec'] && env['bcsec'].user
    end

    def ticket_present?(env)
      env['QUERY_STRING'] =~ /ticket=/
    end
  end
end
