require 'bcsec'

module Bcsec::Rack
  ##
  # Methods used by Rack middleware for reading Bcsec data out of the Rack
  # environment.
  module EnvironmentHelper
    ##
    # Returns the {Configuration} instance for the current request.
    #
    # @return [Bcsec::Configuration]
    def configuration(env)
      env['bcsec.configuration']
    end

    ##
    # Returns the value of the `bcsec.interactive` Rack environment variable.
    #
    # @return [Boolean]
    def interactive?(env)
      env['bcsec.interactive']
    end
  end
end
