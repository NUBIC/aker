require 'aker'

module Aker::Form::Middleware
  ##
  # Extends {LoginResponder} to allow the application to re-render the
  # login form when using {CustomViewsMode}.
  class CustomViewLoginResponder < LoginResponder
    protected

    def unauthenticated(env)
      request = ::Rack::Request.new(env)

      env['aker.form.login_failed'] = true
      env['aker.form.username'] = request['username']

      @app.call(env)
    end
  end
end
