require 'bcsec'

module Bcsec
  module Modes
    autoload :ApiKey, 'bcsec/modes/api_key'
    autoload :Base, 'bcsec/modes/base'
    autoload :Cas, 'bcsec/modes/cas'
    autoload :CasProxy, 'bcsec/modes/cas_proxy'
  end
end
