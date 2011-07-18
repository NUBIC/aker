require 'aker'
require 'warden'

##
# Integration of Aker with {http://rack.rubyforge.org/ Rack}.
module Aker::Rack
  autoload :Authenticate,            'aker/rack/authenticate'
  autoload :ConfigurationHelper,     'aker/rack/configuration_helper'
  autoload :DefaultLogoutResponder,  'aker/rack/default_logout_responder'
  autoload :EnvironmentHelper,       'aker/rack/environment_helper'
  autoload :Facade,                  'aker/rack/facade'
  autoload :Failure,                 'aker/rack/failure'
  autoload :Logout,                  'aker/rack/logout'
  autoload :RequestExt,              'aker/rack/request_ext'
  autoload :SessionTimer,            'aker/rack/session_timer'
  autoload :Setup,                   'aker/rack/setup'

  class << self
    ##
    # Configures all the necessary middleware for Aker into the given
    # rack application stack.  With `Rack::Builder`:
    #
    #      Rack::Builder.new do
    #        Aker::Rack.use_in(self) # self is the builder instance
    #      end
    #
    # Aker's middleware stack relies on the existence of a session,
    # so the session-enabling middleware must be higher in the
    # application stack than Aker.
    #
    # @param [#use] builder the target application builder.  This
    #   could be a `Rack::Builder` object or something that acts like
    #   one.
    # @param [Aker::Configuration,nil] configuration the
    #   configuration to apply to this use.  If nil, uses the global
    #   configuration ({Aker.configuration}).
    # @return [void]
    def use_in(builder, configuration=nil)
      effective_configuration = configuration || Aker.configuration
      unless effective_configuration
        fail "No configuration was provided and there's no global configuration.  " <<
          "Please set one or the other before calling use_in."
      end

      install_modes(effective_configuration)

      builder.use Setup, effective_configuration

      with_mode_middlewares(builder, effective_configuration) do
        effective_configuration.install_middleware(:before_authentication, builder)
        builder.use Warden::Manager do |manager|
          manager.failure_app = Aker::Rack::Failure.new
        end
        builder.use Authenticate
        effective_configuration.install_middleware(:after_authentication, builder)
        builder.use Logout, '/logout'
        builder.use SessionTimer
      end

      builder.use DefaultLogoutResponder, '/logout'
    end

    private

    ##
    # @return [void]
    def install_modes(configuration)
      configuration.registered_modes.each do |mode|
        Warden::Strategies.add(mode.key, mode)
      end
    end

    ##
    # @return [void]
    def with_mode_middlewares(builder, conf)
      mode_classes(conf).each { |m| m.prepend_middleware(builder) if m.respond_to?(:prepend_middleware) }
      yield
      mode_classes(conf).each { |m| m.append_middleware(builder) if m.respond_to?(:append_middleware) }
    end

    def mode_classes(configuration)
      return [] unless configuration

      [configuration.ui_mode, configuration.api_modes].flatten.map do |key|
        Warden::Strategies[key]
      end
    end
  end

  ##
  # @private
  class Slice < Aker::Configuration::Slice
    def initialize
      super do
        policy_parameters :'session-timeout-seconds' => 1800
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Rack::Slice.new)
