require 'aker/rack'

module Aker::Rack
  ##
  # The middleware which makes the aker environment available in the
  # rake environment and authenticates the credentials that the
  # request provides (if any).  It is responsible for determining
  # whether the request is interactive or not and will use the
  # appropriate configured {Aker::Modes mode} based on this decision.
  #
  # You probably don't want to `use` this directly; use
  # {Aker::Rack.use_in} to configure in this middleware and all its
  # dependencies simultaneously.
  #
  # @see Aker::Rack.use_in
  # @see Aker::Configuration#ui_mode
  # @see Aker::Configuration#api_modes
  class Setup
    ##
    # Creates a new instance of the middleware.
    #
    # @param [#call] app the application this middleware is being
    #   wrapped around.
    # @param [Aker::Configuration] configuration the configuration to use for
    #   this instance.
    #
    # @see Aker::Rack.use_in
    def initialize(app, configuration)
      @app = app
      @configuration = configuration
    end

    ##
    # Implements the rack middleware behavior.
    #
    # This class exposes three environment variables to downstream
    # middleware and the app:
    #
    #  * `"aker.configuration"`: the {Aker::Configuration configuration}
    #     for this application.
    #  * `"aker.authority"`: the {Aker::Authorities authority} for
    #    this application.
    #  * `"aker.interactive"`: a boolean indicating whether this
    #    request is being treated as an interactive (UI) or
    #    non-interactive (API) request
    #
    # [There is a related fourth environment variable:
    #
    #  * `"aker.check"`: an instance of {Aker::Rack::Facade}
    #    permitting authentication and authorization queries about the
    #    current user (if any).
    #
    # This fourth variable is added by the {Authenticate} middleware;
    # see its documentation for more.]
    #
    # @param [Hash] env the rack env
    # @return [Array] the standard rack return
    def call(env)
      env['aker.configuration'] = @configuration
      env['aker.authority'] = @configuration.composite_authority
      env['aker.interactive'] = interactive?(env)

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
