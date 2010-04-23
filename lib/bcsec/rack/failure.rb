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
      if interactive?(env)
        ::Warden::Strategies[conf.ui_mode].new(env).on_ui_failure.finish
      else
        headers = {}
        headers["WWW-Authenticate"] =
          conf.api_modes.collect { |mode_key|
            ::Warden::Strategies[mode_key].new(env).challenge
          }.join("\n")
        headers["Content-Type"] = "text/plain"
        [401, headers, [""]]
      end
    end

    private

    def interactive?(env)
      env['bcsec.interactive']
    end

    def configuration(env)
      env['bcsec.configuration']
    end
  end
end
