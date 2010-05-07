require 'bcsec/rack'

module Bcsec::Rack
  class Facade
    attr_accessor :user, :configuration

    def initialize(config, user)
      @configuration = config;
      @user = user
    end

    def authentication_required!
      throw :warden, inauthentic_reason unless authenticated?
    end

    def authenticated?
      inauthentic_reason.nil?
    end

    def permit?(*groups, &block)
      return nil unless user
      user.permit?(*groups, &block)
    end
    alias :permit :permit?

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
