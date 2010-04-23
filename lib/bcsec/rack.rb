require 'bcsec'
require 'warden'

##
# Integration of Bcsec with {http://rack.rubyforge.org/ Rack}.
module Bcsec::Rack
  autoload :Failure, 'bcsec/rack/failure'
  autoload :Setup,   'bcsec/rack/setup'

  class << self
    ##
    # Configures all the necessary middleware for Bcsec into the given
    # rack application stack.  With `Rack::Builder`:
    #
    #      Rack::Builder.new do |builder|
    #        Bcsec::Rack.use_in(builder)
    #      end
    #
    # Bcsec's middleware stack relies on the existence of a session,
    # so the session-enabling middleware must be higher in the
    # application stack than Bcsec.
    #
    # @param [#use] builder the target application builder.  This
    #   could be a `Rack::Builder` object or something that acts like
    #   one.
    # @return [void]
    def use_in(builder)
      install_modes
      install_mode_middleware(builder) if Bcsec.configuration

      builder.use Warden::Manager do |manager|
        manager.failure_app = Bcsec::Rack::Failure.new
      end
      builder.use Setup
    end

    private

    ##
    # @return [void]
    def install_modes
      Bcsec::Modes.constants.
        collect { |s| Bcsec::Modes.const_get(s) }.
        select { |c| c.respond_to?(:key) }.
        each do |mode|
        Warden::Strategies.add(mode.key, mode)
      end
    end

    ##
    # @return [void]
    def install_mode_middleware(builder)
      [Bcsec.configuration.ui_mode, Bcsec.configuration.api_modes].flatten.each do |k|
        mode = Warden::Strategies[k]
        mode.prepend_middleware(builder) if mode.respond_to?(:prepend_middleware)
      end
    end
  end
end
