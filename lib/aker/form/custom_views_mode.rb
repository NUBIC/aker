require 'aker'

module Aker::Form
  ##
  # A specialization of {Mode the :form mode} which allows the
  # Aker-using application to provide the login and logout views.
  #
  # If you use this mode, your application is responsible for
  # rendering appropriate views in response to `GET` to the login and
  # logout paths. By default, the login and logout paths are `/login`
  # and `/logout` (relative to your application). If your application
  # uses other paths, you can change these to match via configuration
  # parameters; see the example below.
  #
  # The login view should arrange for the user's username and password
  # to be `POST`ed to the login path using parameters with those
  # names. If the user is redirected to the login page after
  # attempting to access a protected resource, the URL to the resource
  # she was attempting to access will be passed as `url` in the query
  # string.
  #
  # If the form is being re-rendered because the user's credentials
  # were rejected, the following variables will be available in the
  # rack environment:
  #
  # * `aker.form.login_failed`: `true`
  # * `aker.form.username`: the attempted username, if any
  #
  # In addition to re-rendering the form, It is the responsibility of
  # the custom view to send the appropriate HTTP status (401) in this
  # case.
  #
  # If the POST is successful, the user will be redirected to the
  # originally requested URL (so long as it is still passed along in
  # the `url` parameter). If there was no originally requested
  # URL, the user will be redirected to the root of the application.
  #
  # The logout view may do whatever your application deems
  # appropriate. If you don't provide a custom logout view, you will
  # get the {Aker::Rack::DefaultLogoutResponder very spare default}.
  #
  # @example Configuring custom views and custom paths
  #   Aker.configure {
  #     authority :ldap
  #     ui_mode :custom_form
  #     rack_parameters :login_path => '/accts/log-in', :logout_path => '/accts/log-out'
  #   }
  class CustomViewsMode < Mode
    class << self
      ##
      # The configuration key for this mode.
      # @return [:custom_form]
      def key
        :custom_form
      end

      ##
      # Override parent to prepend nothing.
      # @return [void]
      def prepend_middleware(builder)
      end

      ##
      # Override parent to append only {Middleware::CustomViewLoginResponder}.
      # @return [void]
      def append_middleware(builder)
        builder.use Middleware::CustomViewLoginResponder
      end
    end
  end
end
