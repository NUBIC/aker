module Aker
  autoload :CentralParameters, 'aker/central_parameters'
  autoload :Configuration,     'aker/configuration'
  autoload :Deprecation,       'aker/deprecation'
  autoload :Group,             'aker/group'
  autoload :GroupMemberships,  'aker/group_membership'
  autoload :GroupMembership,   'aker/group_membership'
  autoload :User,              'aker/user'
  autoload :Test,              'aker/test'
  autoload :VERSION,           'aker/version'

  class << self
    ##
    # @return [Configuration,nil] the single configuration for the
    #   system using aker.  Created/updated using {.configure
    #   configure}.
    attr_accessor :configuration

    ##
    # @return [Object,nil] a single authentication/authorization entry
    #   point conforming to the authority protocol as defined by
    #   {Aker::Authorities::Composite}.  By default, it is
    #   automatically derived from the {.configuration configuration}.
    # @see Aker::Configuration#composite_authority
    attr_accessor :authority

    ##
    # Create/update the global aker configuration.  Accepts a block
    # containing expressions in the {Configuration} DSL.
    #
    # @see Aker.configuration
    # @return [Configuration]
    def configure(&block)
      @configuration ||= Aker::Configuration.new
      @configuration.enhance(&block)
    end

    def authority
      @authority || (@configuration && @configuration.composite_authority)
    end
  end
end

# These files are required instead of autoloaded so that their
# configuration slices are installed immediately.
require 'aker/authorities'
require 'aker/cas'
require 'aker/ldap'
require 'aker/modes'
require 'aker/rack'
