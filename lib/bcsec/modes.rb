require 'bcsec'

module Bcsec
  module Modes
    autoload :Base, 'bcsec/modes/base'
    autoload :Cas, 'bcsec/modes/cas'
    autoload :CasProxy, 'bcsec/modes/cas_proxy'
    autoload :Form, 'bcsec/modes/form'
    autoload :HttpBasic, 'bcsec/modes/http_basic'
    autoload :Rfc2617,   'bcsec/modes/rfc_2617'
    autoload :Middleware, 'bcsec/modes/middleware'
  end
end
