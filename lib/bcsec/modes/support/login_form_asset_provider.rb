require 'bcsec/modes/support'
require 'erb'
require 'rack'

module Bcsec::Modes::Support
  ##
  # Provides HTML and CSS for login forms.
  #
  # @author David Yip
  module LoginFormAssetProvider
    include Rack::Utils

    ##
    # Where to look for HTML and CSS assets.
    #
    # This is currently hardcoded as `(bcsec gem root)/bcsec/modes/middleware/form`.
    #
    # @return [String] a directory path
    def asset_root
      File.expand_path(File.join(File.dirname(__FILE__),
                                 %w(.. .. .. ..),
                                 %w(assets bcsec modes middleware form)))
    end

    ##
    # Provides the HTML for the login form.
    #
    # This method expects to find a `login.html.erb` ERB template in
    # {#asset_root}.  The ERB template is evaluated in an environment where
    # a local variable named `script_name` is bound to the value of the
    # `SCRIPT_NAME` Rack environment variable, which is useful for CSS and
    # form action URL generation.
    #
    # @param env [Rack environment] a Rack environment
    # @param [Hash] options rendering options
    # @option options [Boolean] :login_failed If true, will render a failure message
    # @option options [Boolean] :logged_out If true, will render a logout notification
    # @option options [String] :username Text for the username field
    # @option options [String] :url A URL to redirect to upon successful login
    # @return [String] HTML data
    def login_html(env, options = {})
      script_name = env['SCRIPT_NAME']
      template = File.read(File.join(asset_root, 'login.html.erb'))
      ERB.new(template).result(binding)
    end

    ##
    # Provides the CSS for the login form.
    #
    # @return [String] CSS data
    def login_css
      File.read(File.join(asset_root, 'login.css'))
    end
  end
end
