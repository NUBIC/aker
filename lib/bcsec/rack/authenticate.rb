require 'bcaudit'
require 'bcsec'

module Bcsec::Rack
  class Authenticate
    include EnvironmentHelper

    def initialize(app)
      @app = app
    end

    ##
    # Authenticates incoming requests using Warden.
    #
    # Additionally, this class exposes the `bcsec` environment variable to
    # downstream middleware and the app.  It is an instance of
    # {Bcsec::Rack::Facade} permitting authentication and authorization queries
    # about the current user (if any).
    def call(env)
      configuration = configuration(env)
      warden = env['warden']

      with_temporary_audit_info(env) do
        if interactive?(env)
          warden.authenticate(configuration.ui_mode)
        else
          warden.authenticate(*configuration.api_modes)
        end
      end

      env['bcsec'] = Facade.new(configuration, warden.user)

      @app.call(env)
    end

    private

    def with_temporary_audit_info(env)
      Bcaudit::Middleware.set_audit_info_from(env)
      yield
      Bcaudit::AuditInfo.clear
    end
  end
end
