require 'bcsec/rack'

module Bcsec::Rack
  ##
  # Provides a simple interface which bcsec-using rack apps may use to
  # indicate that authentication or authorization is required for a
  # particular action.
  #
  # An instance of this class is available in the rack environment
  # under the `"bcsec"` key.
  class Facade
    ##
    # The current authenticated user.
    #
    # @return [Bcsec::User]
    attr_accessor :user

    ##
    # The bcsec configuration in effect for this application.
    #
    # @return [Bcsec::Configuration]
    attr_accessor :configuration

    def initialize(config, user)
      @configuration = config
      @user = user
    end

    ##
    # Indicates that authentication is required for a particular
    # request.  If the user is not authenticated, any application code
    # after this method is called will not be executed.  The user will
    # be directed to authenticate according to their access style
    # (ui vs. api) and the application configuration (i.e., the
    # appropriate {Modes mode}).
    #
    # If the application has a {Bcsec::Configuration#portal portal}
    # configured, bcsec will also check that the user has access to
    # that portal.  If the user is authenticated but does not have
    # access to the portal, she will get a `403 Forbidden` response.
    #
    # @see #authenticated?
    # @return [void]
    def authentication_required!
      throw :warden, inauthentic_reason unless authenticated?
    end

    ##
    # Returns true if there is an authenticated user, false otherwise.
    # This check follows the same rules as
    # {#authentication_required!}, including the portal check.
    # However, it does not halt processing if the user is not
    # authenticated.
    #
    # @return [Boolean]
    def authenticated?
      inauthentic_reason.nil?
    end

    ##
    # A shortcut to invoking {Bcsec::User#permit?} on the {#user
    # current user}.  As with that method, the block is optional.
    #
    # This method safely handles the case where there is no user
    # logged in.
    #
    # @param [Array<#to_sym>] groups
    # @return [Boolean, Object, nil] `nil` if there's no one logged in;
    #   otherwise the same as {Bcsec::User#permit?}.
    def permit?(*groups, &block)
      return nil unless user
      user.permit?(*groups, &block)
    end
    alias :permit :permit?

    ##
    # Indicates that a user must be in one of the specified groups to
    # proceed.  If there is a user logged in and she is not in any of
    # the specified groups, she will get a `403 Forbidden` response.
    # If the user is not logged in, she will be prompted to log in
    # (just like with {#authentication_required!}).
    #
    # @return [void]
    def permit!(*groups)
      authentication_required!
      throw :warden, :groups_required => groups unless user.permit?(*groups)
    end

    private

    def inauthentic_reason
      @inauthentic_reason =
        if !user
          { :login_required => true }
        elsif !configuration.portal? || user.may_access?(configuration.portal)
          nil
        else
          { :portal_required => configuration.portal }
        end
    end
  end
end
