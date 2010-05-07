require 'bcsec/rack'
require 'warden'

module Bcsec::Rack
  ##
  # The Rack endpoint which handles authentication failures.
  #
  # @see Bcsec::Rack.use_in
  # @see http://wiki.github.com/hassox/warden/failures
  #      Warden failures documentation
  class Failure
    ##
    # Receives the rack environment in case of a failure and renders a
    # response based on the interactiveness of the request and the
    # nature of the configured modes.
    #
    # @param [Hash] env a rack environment
    #
    # @return [Array] a rack response
    def call(env)
      conf = configuration(env)
      if login_required?(env)
        if interactive?(env)
          ::Warden::Strategies[conf.ui_mode].new(env).on_ui_failure.finish
        else
          headers = {}
          headers["WWW-Authenticate"] =
            conf.api_modes.collect { |mode_key|
            ::Warden::Strategies[mode_key].new(env).challenge
          }.join("\n")
          headers["Content-Type"] = "text/plain"
          [401, headers, ["Authentication required"]]
        end
      else
        msg = "#{user(env).username} may not use this page."
        Rack::Response.
          new(
              "<html><head><title>Authorization denied</title></head><body>#{msg}</body></html>",
              403,
              "Content-Type" => "text/html").finish
      end
    end

    private

    def interactive?(env)
      env['bcsec.interactive']
    end

    def configuration(env)
      env['bcsec.configuration']
    end

    def login_required?(env)
      env['warden.options'][:login_required]
    end

    def user(env)
      env['bcsec'].user
    end
  end
end
