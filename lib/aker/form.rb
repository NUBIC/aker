require 'aker'

module Aker
  ##
  # The Aker mode that supports a traditional HTML login form, and its
  # support infrastructure.
  module Form
    autoload :LoginFormAssetProvider, 'aker/form/login_form_asset_provider'
    autoload :Middleware,             'aker/form/middleware'
    autoload :Mode,                   'aker/form/mode'

    ##
    # @private
    class Slice < Aker::Configuration::Slice
      def initialize
        super do
          register_mode Mode
        end
      end
    end
  end
end

Aker::Configuration.add_default_slice(Aker::Form::Slice.new)
