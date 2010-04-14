require 'bcsec'

module Bcsec
  module Modes
    ##
    # A noninteractive and interactive mode that provides HTTP Basic
    # authentication.
    #
    # This mode operates noninteractively when an Authorization header with a
    # Basic challenge is present.  It operates interactively when it is
    # configured as an interactive authentication mode.
    #
    # @author David Yip
    class HttpBasic < Bcsec::Modes::Base
      def self.key
        :http_basic
      end
    end
  end
end
