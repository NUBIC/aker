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
    ##
    # Creates a new instance of the middleware.
    #
    # @param [#call] app the application this middleware is being
    #   wrapped around.
    # @param [Bcsec::Configuration] configuration the configuration to use for
    #   this instance.
    #
    # @see Bcsec::Rack.use_in
    def initialize(app, configuration)
      @app = app
      @configuration = configuration
    end

    ##
    # Implements the rack middleware behavior.
    #
    # This class exposes four environment variables to downstream
    # middleware and the app:
    #
    #  * `"bcsec"`: an instance of {Bcsec::Rack::Facade} permitting
    #    authentication and authorization queries about the current
    #    user (if any).
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
      env['bcsec.configuration'] = @configuration
      env['bcsec.authority'] = @configuration.composite_authority
      env['bcsec.interactive'] = interactive?(env)

      @app.call(env)
    end

    ##
    # Determines if the given rack env represents an interactive
    # request.
    #
    # @return [Boolean, nil] true if interactive, false or nil otherwise
    def interactive?(env)
      @configuration.api_modes.empty? or
        env["HTTP_ACCEPT"] =~ %r{text/html} or
        env["HTTP_USER_AGENT"] =~ %r{Mozilla}
    end
  end
end
