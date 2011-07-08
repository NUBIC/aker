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
    # Whether the current request is interactive.
    #
    # @see Bcsec::Rack::Setup#call
    # @see Bcsec::Rack::Setup#interactive?
    # @return [Boolean]
    def interactive?(env)
      env['bcsec.interactive']
    end

    ##
    # The authority to use for credential validation.
    #
    # @return [Object]
    def authority(env)
      env['bcsec.authority']
    end
  end
end
