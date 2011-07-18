require 'aker'

module Aker::Rack
  ##
  # Methods used by Rack middleware for reading Aker data out of the Rack
  # environment.
  module EnvironmentHelper
    ##
    # Returns the {Configuration} instance for the current request.
    #
    # @return [Aker::Configuration]
    def configuration(env)
      env['aker.configuration']
    end

    ##
    # Whether the current request is interactive.
    #
    # @see Aker::Rack::Setup#call
    # @see Aker::Rack::Setup#interactive?
    # @return [Boolean]
    def interactive?(env)
      env['aker.interactive']
    end

    ##
    # The authority to use for credential validation.
    #
    # @return [Object]
    def authority(env)
      env['aker.authority']
    end
  end
end
