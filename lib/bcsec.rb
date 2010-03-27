module Bcsec
  VERSION = File.read(File.expand_path('../../VERSION', __FILE__)).strip

  class << self
    attr_accessor :configuration

    def configure(&block)
      @configuration ||= Bcsec::Configuration.new
      @configuration.enhance(&block)
    end
  end
end
