require 'bcsec'

module Bcsec
  module Modes
    ##
    #
    # An interactive mode that provides CAS authentication conformant to CAS 2.
    # This authenticator implements the client end of CAS via RubyCAS-Client.
    #
    # This mode does _not_ handle CAS proxying because CAS proxying is
    # noninteractive.  See {CasProxy} for that.
    #
    # @see http://github.com/gunark/rubycas-client
    #      RubyCAS-Client at Github
    # @see http://www.jasig.org/cas/protocol
    #      CAS 2 protocol specification
    #
    # @author David Yip
    class Cas < Bcsec::Modes::Base
      ##
      # A key that refers to this mode; used for configuration convenience.
      #
      # @return [Symbol]
      def self.key
        :cas
      end
    end
  end
end
