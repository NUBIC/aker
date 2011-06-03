require 'bcsec'

module Bcsec::Modes::Middleware::Form
  ##
  # Methods used by form middleware for reading values out of a
  # {Configuration} object.
  #
  #
  # Expected interface
  # ------------------
  #
  # These methods expect the presence of a `configuration` attribute
  # reader.
  module ConfigurationHelper
    ##
    # Whether a custom login page will be provided by the application.
    #
    # @return [Boolean]
    def using_custom_login_page?
      configuration.parameters_for(:form)[:use_custom_login_page]
    end

    ##
    # Whether a custom logout page is in use.
    #
    # @return [Boolean]
    def using_custom_logout_page?
      configuration.parameters_for(:form)[:use_custom_logout_page]
    end
  end
end
