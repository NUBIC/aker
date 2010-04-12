require 'tree'

module Bcsec
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  autoload :Authorities,       'bcsec/authorities'
  autoload :CentralParameters, 'bcsec/central_parameters'
  autoload :Configuration,     'bcsec/configuration'
  autoload :Deprecation,       'bcsec/deprecation'
  autoload :Group,             'bcsec/group'
  autoload :GroupMemberships,  'bcsec/group_membership'
  autoload :GroupMembership,   'bcsec/group_membership'
  autoload :User,              'bcsec/user'
  autoload :Modes,             'bcsec/modes'

  class << self
    ##
    # @return [Configuration,nil] the single configuration for the
    #   system using bcsec.  Created/updated using {.configure
    #   configure}.
    attr_accessor :configuration

    ##
    # Create/update the global bcsec configuration.  Accepts a block
    # containing expressions in the {Configuration} DSL.
    #
    # @see Bcsec.configuration
    # @return [Configuration]
    def configure(&block)
      @configuration ||= Bcsec::Configuration.new
      @configuration.enhance(&block)
    end
  end
end
