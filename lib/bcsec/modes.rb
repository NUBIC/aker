require 'bcsec'

module Bcsec
  ##
  # The namespace for modes in Bcsec.
  #
  # A mode implements an authentication protocol, and is classified as a _UI
  # mode_, an _API mode_, or both.  UI modes are intended for interactive use;
  # API modes are intended for non-interactive use.
  #
  # Bcsec 2 ships with four modes:
  #
  # - {Bcsec::Modes::Cas :cas} is a UI mode that provides interactive login via
  #   a CAS server.
  # - {Bcsec::Modes::CasProxy :cas_proxy} is an API mode that implements the
  #   CAS proxying protocol.
  # - {Bcsec::Modes::Form :form} is a UI mode that provides an HTML form that
  #   prompts for username and password.
  # - {Bcsec::Modes::HttpBasic :http_basic} is an API/UI mode that implements
  #   the HTTP Basic authentication protocol.  (It's both an API and UI mode
  #   because it can be used by automated Web clients and humans alike.)
  #
  # Bcsec 2 permits applications to use as many API modes as they wish, but
  # requires that applications have one and only one UI mode.  The default UI
  # mode is `:form`.
  #
  # @see Bcsec::Configuration#ui_mode=
  # @see Bcsec::Configuration#api_modes=
  module Modes
    autoload :Base,       'bcsec/modes/base'
    autoload :Cas,        'bcsec/modes/cas'
    autoload :CasProxy,   'bcsec/modes/cas_proxy'
    autoload :Form,       'bcsec/modes/form'
    autoload :HttpBasic,  'bcsec/modes/http_basic'
    autoload :Middleware, 'bcsec/modes/middleware'
    autoload :Support,    'bcsec/modes/support'

    class Slice < Bcsec::Configuration::Slice
      def initialize
        super do
          register_mode Bcsec::Modes::Cas
          register_mode Bcsec::Modes::CasProxy
          register_mode Bcsec::Modes::Form
          register_mode Bcsec::Modes::HttpBasic
        end
      end
    end
  end
end

Bcsec::Configuration.add_default_slice(Bcsec::Modes::Slice.new)
