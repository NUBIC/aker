require 'aker'

module Aker
  ##
  # Mode support code.
  #
  # A mode implements an authentication protocol, and is classified as a _UI
  # mode_, an _API mode_, or both.  UI modes are intended for interactive use;
  # API modes are intended for non-interactive use.
  #
  # Aker ships with five modes:
  #
  # - {Aker::Cas::ServiceMode :cas} is a UI mode that provides interactive login via
  #   a CAS server.
  # - {Aker::Cas::ProxyMode :cas_proxy} is an API mode that implements the
  #   CAS proxying protocol.
  # - {Aker::Form::Mode :form} is a UI mode that provides an HTML form that
  #   prompts for username and password.
  # - {Aker::Form::CustomViewsMode :custom_form} is a specialization
  #   of `:form` for apps that wish to provide their own form views.
  # - {Aker::Modes::HttpBasic :http_basic} is an API/UI mode that implements
  #   the HTTP Basic authentication protocol.  (It's both an API and UI mode
  #   because it can be used by automated Web clients and humans alike.)
  #
  # Aker permits applications to use as many API modes as they wish,
  # but requires that applications have one and only one UI mode.  The
  # default UI mode is `:form`.
  #
  # @see Aker::Configuration#ui_mode=
  # @see Aker::Configuration#api_modes=
  module Modes
    autoload :Base,       'aker/modes/base'
    autoload :HttpBasic,  'aker/modes/http_basic'
    autoload :Support,    'aker/modes/support'

    ##
    # @private
    class Slice < Aker::Configuration::Slice
      def initialize
        super do
          register_mode Aker::Modes::HttpBasic
        end
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Modes::Slice.new)
