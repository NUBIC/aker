require 'bcsec'

module Bcsec::Rack
  ##
  # Middleware that permits a Web application to enforce a session inactivity
  # limit.
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
  # Therefore, if you're using Rack middleware to provide session management,
  # you'll need to have the session management middleware run before
  # SessionTimer.  Most Bcsec configurations will do this, so it's not generally
  # something that you'll need to worry about.
  #
  # SessionTimer also expects `GET /logout` to do all necessary work to log out
  # a user.  Installing {Bcsec::Rack::Logout} before SessionTimer is one way to
  # satisfy this expectation.
  class SessionTimer
    def initialize(app)
      @app = app
    end

    ##
    # Determines whether the incoming request arrived within the
    # {#timeout_window timeout window}.  If it did, then the request is passed
    # onto the rest of the Rack stack; otherwise, the user is redirected to `GET
    # /logout`.
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
        Rack::Response.new { |r| r.redirect('/logout') }
      end
    end

    private

    def configuration(env)
      env['bcsec.configuration']
    end

    ##
    # Session timeout length in seconds from Bcsec's `policy` parameter group.
    #
    # If no session timeout is set, this returns zero.
    #
    # @return [Numeric]
    def window_size(env)
      configuration(env).parameters_for(:policy)[%s(session-timeout)].to_i
    end
  end
end
