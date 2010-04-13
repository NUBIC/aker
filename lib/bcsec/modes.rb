require 'bcsec'

module Bcsec
  module Modes
    autoload :ApiKey, 'bcsec/modes/api_key'
    autoload :Base, 'bcsec/modes/base'
    autoload :Cas, 'bcsec/modes/cas'
  end
end
