require 'bcsec'

module Bcsec::Rack
  ##
  # The middleware which actually performs authentication according to
  # the mode that applies to the request (if any). Most of the heavy
  # lifting is performed by Warden.
  class Authenticate
    include EnvironmentHelper

    def initialize(app)
      @app = app
    end

    ##
    # Authenticates incoming requests using Warden.
    #
    # Additionally, this class exposes the `bcsec` environment
    # variable to downstream middleware and the app.  It is an
    # instance of {Bcsec::Rack::Facade} permitting authentication and
    # authorization queries about the current user (if any).
    def call(env)
      configuration = configuration(env)
      warden = env['warden']

      if interactive?(env)
        warden.authenticate(configuration.ui_mode)
      else
        warden.authenticate(*configuration.api_modes)
      end

      env['bcsec'] = Facade.new(configuration, warden.user)

      @app.call(env)
    end
  end
end
