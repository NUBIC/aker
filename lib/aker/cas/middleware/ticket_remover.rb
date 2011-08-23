require 'aker'

module Aker::Cas::Middleware
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
        request = Rack::Request.new(env)
        url = Aker::Cas::ServiceUrl.service_url(request)
        body = request.get? ? [%Q{<a href="#{url}">Click here to continue</a>}] : []

        [301, { 'Location' => url, 'Content-Type' => 'text/html' }, body]
      else
        @app.call(env)
      end
    end

    private

    def authenticated?(env)
      env['aker.check'] && env['aker.check'].user
    end

    def ticket_present?(env)
      env['QUERY_STRING'] =~ /ticket=/
    end
  end
end
