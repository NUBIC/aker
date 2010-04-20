require 'bcsec/rack'

module Bcsec::Rack
  ##
  # The middleware which makes the bcsec environment available in the
  # rake environment and authenticates the credentials that the
  # request provides (if any).  It is responsible for determining
  # whether the request is interactive or not and will use the
  # appropriate configured {Bcsec::Modes mode} based on this decision.
  #
  # You probably don't want to `use` this directly; use
  # {Bcsec::Rack.use_in} to configure in this middleware and all its
  # dependencies simultaneously.
  #
  # @see Bcsec::Rack.use_in
  # @see Bcsec::Configuration#ui_mode
  # @see Bcsec::Configuration#api_modes
  class Setup
    def initialize(app)
      @app = app
    end

    ##
    # Implements the rack middleware behavior.
    #
    # This class exposes three environment variables to downstream
    # middleware and the app:
    #
    #  * `"bcsec.configuration"`: the {Bcsec::Configuration configuration}
    #     for this application.
    #  * `"bcsec.authority"`: the {Bcsec::Authorities authority} for
    #    this application.
    #  * `"bcsec.interactive"`: a boolean indicating whether this
    #    request is being treated as an interactive (UI) or
    #    non-interactive (API) request
    #
    # @param [Hash] env the rack env
    # @return [Array] the standard rack return
    def call(env)
      env['bcsec.configuration'] = configuration
      env['bcsec.authority'] = authority
      env['bcsec.interactive'] = interactive?(env)

      warden = env['warden']
      if env['bcsec.interactive'] || configuration.api_modes.empty?
        warden.authenticate(configuration.ui_mode)
      else
        warden.authenticate(*configuration.api_modes)
      end

      @app.call(env)
    end

    ##
    # Determines if the given rack env represents an interactive
    # request.
    #
    # @return [Boolean]
    def interactive?(env)
      env["HTTP_ACCEPT"] =~ %r{text/html}
    end

    private

    def configuration
      Bcsec.configuration
    end

    def authority
      Bcsec.authority
    end
  end
end
