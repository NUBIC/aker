require 'bcsec'

module Bcsec::Authorities
  ##
  # An authority which grants all users access to the Bcsec
  # environment's configured portal.  This allows you to mix
  # authentication-only access control and group-authorization access
  # control in the same application.
  #
  # This authority does not provide any credential validation, so it
  # can't be used on its own.  Combine it with one of the
  # {Bcsec::Authorities others}.
  #
  # If you only need authentication-only access control, it will be
  # easier to just omit the {Bcsec::Configuration#portal portal} from
  # your bcsec configuration.
  class AutomaticAccess
    def initialize(configuration)
      unless configuration.portal?
        raise "#{self.class.to_s.split('::').last} is unnecessary " <<
          "if you don't have a portal configured."
      end
      @portal = configuration.portal
    end

    ##
    # Adds the configured portal to the user if necessary.
    #
    # @return [Bcsec::User]
    def amplify!(user)
      user.portals << @portal unless user.portals.include?(@portal)
      user.default_portal = @portal unless user.default_portal
      user
    end
  end
end
