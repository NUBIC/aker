require 'bcsec'

module Bcsec::Rack
  ##
  # Middleware that permits a Web application to enforce a session inactivity
  # limit.
  #
  # The session inactivity limit is determined by the `session-timeout`
  # parameter in Bcsec's `policy` parameter group.  It defaults to 1800 seconds
  # (30 minutes), and can be overridden by a {Bcsec::ConfiguratorLanguage Bcsec
  # configuration block} or {Bcsec::CentralParameters central parameters file}.
  # To disable session timeout, set `session-timeout` to `nil` or `0`.
  #
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
  #     store ta in the Rack environment as bcsec.timeout_at
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
  #       log out the user
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
  # SessionTimer also expects `GET /logout` to do all necessary work to log out
  # a user.
  #
  # {Bcsec::Rack.use_in} sets up a middleware stack that satisfies these
  # requirements.
  class SessionTimer
    def initialize(app)
      @app = app
    end

    ##
    # Determines whether the incoming request arrived within the timeout
    # window.  If it did, then the request is passed onto the rest of the Rack
    # stack; otherwise, the user is redirected to `GET /logout`.
    #
    def call(env)
      now              = Time.now.to_i
      session          = env['rack.session']
      window_size      = window_size(env)
      previous_timeout = session['bcsec.last_request_at']

      return @app.call(env) unless window_size > 0

      env['bcsec.timeout_at'] = now + window_size
      session['bcsec.last_request_at'] = now

      return @app.call(env) unless previous_timeout

      if now < previous_timeout + window_size
        @app.call(env)
      else
        Rack::Response.new { |r| r.redirect('/logout') }.finish
      end
    end

    private

    def configuration(env)
      env['bcsec.configuration']
    end

    def window_size(env)
      configuration(env).parameters_for(:policy)[%s(session-timeout)].to_i
    end
  end
end
