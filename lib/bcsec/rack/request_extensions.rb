require 'bcsec'

module Bcsec::Rack
  ##
  # Extensions for `Rack::Request`.
  #
  # To use these, `include` them into `Rack::Request`.
  module RequestExtensions
    ##
    # Returns the value of the `bcsec.interactive` Rack environment variable.
    #
    # @return [Boolean]
    def interactive?
      env['bcsec.interactive']
    end
  end
end
