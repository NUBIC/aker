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
    #      Rack::Builder.new do
    #        Bcsec::Rack.use_in(self) # self is the builder instance
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

      with_mode_middlewares(builder) do
        builder.use Warden::Manager do |manager|
          manager.failure_app = Bcsec::Rack::Failure.new
        end
        builder.use Setup
      end
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
    def with_mode_middlewares(builder)
      mode_classes.each { |m| m.prepend_middleware(builder) if m.respond_to?(:prepend_middleware) }
      yield
      mode_classes.each { |m| m.append_middleware(builder) if m.respond_to?(:append_middleware) }
    end

    def mode_classes
      return [] unless configuration

      [configuration.ui_mode, configuration.api_modes].flatten.map do |key|
        Warden::Strategies[key]
      end
    end

    def configuration
      Bcsec.configuration
    end
  end
end
