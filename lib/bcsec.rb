module Bcsec
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  autoload :Authorities,       'bcsec/authorities'
  autoload :CentralParameters, 'bcsec/central_parameters'
  autoload :Configuration,     'bcsec/configuration'
  autoload :Deprecation,       'bcsec/deprecation'

  class << self
    attr_accessor :configuration

    def configure(&block)
      @configuration ||= Bcsec::Configuration.new
      @configuration.enhance(&block)
    end
  end
end
