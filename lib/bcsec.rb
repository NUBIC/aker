module Bcsec
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  autoload :Authorities,       'bcsec/authorities'
  autoload :Cas,               'bcsec/cas'
  autoload :CentralParameters, 'bcsec/central_parameters'
  autoload :Configuration,     'bcsec/configuration'
  autoload :Deprecation,       'bcsec/deprecation'
  autoload :Group,             'bcsec/group'
  autoload :GroupMemberships,  'bcsec/group_membership'
  autoload :GroupMembership,   'bcsec/group_membership'
  autoload :Rack,              'bcsec/rack'
  autoload :User,              'bcsec/user'
  autoload :Modes,             'bcsec/modes'
  autoload :Test,              'bcsec/test'

  class << self
    ##
    # @return [Configuration,nil] the single configuration for the
    #   system using bcsec.  Created/updated using {.configure
    #   configure}.
    attr_accessor :configuration

    ##
    # @return [Object,nil] a single authentication/authorization entry
    #   point conforming to the authority protocol as defined by
    #   {Bcsec::Authorities::Composite}.  By default, it is
    #   automatically derived from the {.configuration configuration}.
    # @see Bcsec::Configuration#composite_authority
    attr_accessor :authority

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

    def authority
      @authority || (@configuration && @configuration.composite_authority)
    end
  end
end
