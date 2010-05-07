require 'bcsec/modes/support'

module Bcsec::Modes::Support
  module LoginFormRenderer
    ##
    # The form asset provider.
    #
    # @see FormAssetProvider
    # @return [#login_html, #login_css] a form asset provider
    attr_accessor :assets

    ##
    # An HTML form for logging in.
    #
    # @param env the Rack environment
    # @param args additional arguments to pass to the asset provider's `login_html` method
    # @return [String] login form HTML
    def provide_login_html(env, *args)
      assets.login_html(env, *args)
    end

    ##
    # CSS for the form provided by {provide_login_html}.
    #
    # @return [String] login form CSS
    def provide_login_css
      assets.login_css
    end
  end
end
