require 'aker'

module Aker::Rack
  ##
  # Middleware that permits a Web application to enforce a session inactivity
  # limit. When a request is made after the session expires, the
  # middleware resets the session, forcing the user to be reauthenticated.
  #
  # The session inactivity limit is determined by the `session-timeout-seconds`
  # parameter in Aker's `policy` parameter group.  It defaults to 1800 seconds
  # (30 minutes), and can be overridden by a {Aker::ConfiguratorLanguage Aker
  # configuration block} or {Aker::CentralParameters central parameters file}.
  # To disable session timeout, set `session-timeout-seconds` to `nil` or `0`.
  #
  # Algorithm
  # =========
  #
  # On each request:
  #
  #     let lr = timestamp of last request,
  #         cr = timestamp of current request,
  #         st = session timeout from configuration,
  #         ta = lr + st
  #
  #     if st is nil
  #       pass control to rest of application
  #     end
  #
  #     store ta in the Rack environment as aker.timeout_at
  #     lr := cr
  #     store lr in the session
  #
  #     if lr is nil
  #       pass control to rest of application
  #     end
  #
  #     if cr is in [lr, ta]
  #       pass control to rest of application
  #     else
  #       reset session
  #       pass control to rest of application
  #     end
  #
  #
  # Requirements
  # ============
  #
  # SessionTimer expects a session manager that behaves like a `Rack::Session`
  # session manager to be present in the `rack.session` Rack environment
  # variable.
  #
  # SessionTimer should be configured earlier in the middleware stack
  # than any middleware which checks for cached
  # credentials. {Aker::Rack.use_in} arranges things this way.
  class SessionTimer
    include EnvironmentHelper
    include ConfigurationHelper

    def initialize(app)
      @app = app
    end

    ##
    # Determines whether the incoming request arrived within the timeout
    # window.  If it did, then the request is passed onto the rest of the Rack
    # stack; otherwise, the user is redirected to the configured
    # logout path.
    #
    def call(env)
      now              = Time.now.to_i
      session          = env['rack.session']
      window_size      = window_size(env)
      previous_timeout = session['aker.last_request_at']

      return @app.call(env) unless window_size > 0

      env['aker.timeout_at'] = now + window_size
      session['aker.last_request_at'] = now

      return @app.call(env) unless previous_timeout

      if now >= previous_timeout + window_size
        env['aker.session_expired'] = true
        env['warden'].logout
      end
      @app.call(env)
    end

    private

    def window_size(env)
      configuration(env).parameters_for(:policy)[%s(session-timeout-seconds)].to_i
    end
  end
end
