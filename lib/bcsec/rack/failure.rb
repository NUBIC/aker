require 'bcsec/rack'
require 'warden'

module Bcsec::Rack
  class Failure
    def call(env)
      conf = configuration(env)
      if interactive?(env)
        ::Warden::Strategies[conf.ui_mode].new(env).on_ui_failure
      else
        headers = {}
        headers["WWW-Authenticate"] =
          conf.api_modes.collect { |mode_key|
            mode = ::Warden::Strategies[mode_key].new(env)
            "#{mode.scheme} realm=\"#{conf.portal? ? conf.portal : Bcsec}\""
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
