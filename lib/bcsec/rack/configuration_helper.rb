require 'bcsec'

module Bcsec::Rack
  ##
  # Methods used by Rack middleware for reading configuration data out of the
  # Rack environment.
  module ConfigurationHelper
    include EnvironmentHelper

    ##
    # Whether a custom login page will be provided by the application.
    #
    # @return [Boolean]
    def using_custom_login_page?(env)
      configuration(env).parameters_for(:rack)[:use_custom_login_page]
    end

    ##
    # Whether a custom logout page is in use.
    #
    # @return [Boolean]
    def using_custom_logout_page?(env)
      configuration(env).parameters_for(:rack)[:use_custom_logout_page]
    end
  end
end
