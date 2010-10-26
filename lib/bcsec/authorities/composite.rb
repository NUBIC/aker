require 'bcsec'

module Bcsec::Authorities
  ##
  # This authority provides a uniform entry point for multiple
  # authorities.
  #
  # The documentation on each method describes how the implementation
  # for a specific authority should work in addition to the way this
  # authority aggregates results.  For any particular authority, all
  # methods are optional (of course, it would be pointless to
  # configure in an authority which doesn't implement any of them).
  class Composite
    ##
    # The ordered series of authorities whose results this authority
    # aggregates.  The members of this array should implement one or
    # more of the methods in the authority informal interface (i.e.,
    # the other methods in this class).
    #
    # @return [Array]
    attr_accessor :authorities

    ##
    # Creates a new instance.
    #
    # @param [Bcsec::Configuration] config the configuration to use
    #   for this authority.  The {#authorities} attribute for this
    #   instance will default to {Bcsec::Configuration#authorities
    #   config.authorities}.  Its {Bcsec::Configuration#portal portal}
    #   (if any) will be used as the {Bcsec::User#default_portal
    #   default portal} for any authenticated users which don't have
    #   one.
    def initialize(config)
      @config = config
    end

    def authorities
      @authorities || @config.authorities
    end

    ##
    # The main authentication and authorization entry point for an
    # authority.  A concrete authority can return one of four things
    # from its implementation of this method:
    #
    # * A {Bcsec::User} instance if the credentials are valid.  The
    #   instance represents the user that corresponds to these
    #   credentials, with all the attributes and authorization
    #   information that the verifying authority knows about.
    # * `nil` if the credentials aren't valid according to the
    #   authority.
    # * `false` if the authority wants to prevent the presenter of
    #   these credentials from authenticating, even if another
    #   authority says they are valid.
    # * `:unsupported` if the authority can never authenticate
    #   credentials of the provided kind.  Semantically this is the
    #   same as `nil`, but it allows `Composite` to provide a useful
    #   debugging message if none of the authorities are capable of
    #   validating a submitted kind.
    #
    # The composite implementation provided by this class does the
    # following:
    #
    # * Executes `valid_credentials?` on all the configured authorities
    #   that implement it.
    # * Returns `false` if any of the authorities return `false`.
    # * Returns `nil` if none of the authorities returned a user.
    # * Selects the first user returned by any of the authorities.
    # * Returns `false` if any of the authorities {#veto? veto} the
    #   user.
    # * Otherwise returns the user, {#amplify! amplified}.
    #
    # On failure, the {#on_authentication_failure} callback is called
    # on any authority which provides it.  Similarly on success, the
    # {#on_authentication_success} callback is called on all the
    # authorities which support it.
    #
    # @param [Symbol] kind a symbol describing the semantics of the
    #   supplied credentials.  Different authorities may support
    #   different kinds (or multiple authorities may support the same
    #   kind).
    # @param [Array] *credentials the actual credentials.  The form of
    #   these is dependent on the kind.
    #
    # @return [Bcsec::User,false,nil] the aggregated result of calling
    #   `valid_credentials?` on all the configured {#authorities}.
    #   If the credentials are valid, the returned user will already
    #   be {#amplify! amplified}.
    def valid_credentials?(kind, *credentials)
      results = poll(:valid_credentials?, kind, *credentials)
      if results.empty?
        raise "No authentication-providing authority is configured.  " <<
          "At least one authority must implement #valid_credentials?."
      end
      user, authenticating_authority = results.detect { |r, authority| r && r != :unsupported }

      unless user
        msg =
          if results.collect { |r, auth| r }.uniq == [:unsupported]
            "no configured authorities support #{kind.inspect} credentials"
          else
            "invalid credentials"
          end
        on_authentication_failure(nil, kind, credentials, msg)
        return nil
      end

      vc_vetoers = results.select { |r, authority| r == false }.collect { |r, authority| authority }
      unless vc_vetoers.empty?
        msg = "credentials vetoed by #{vc_vetoers.collect(&:to_s).join(', ')}"
        on_authentication_failure(user, kind, credentials, msg)
        return false
      end

      veto_vetoers = poll(:veto?, user).
        select { |result, authority| result }.collect { |result, authority| authority }
      unless veto_vetoers.empty?
        msg = "user vetoed by #{veto_vetoers.collect(&:to_s).join(', ')}"
        on_authentication_failure(user, kind, credentials, msg)
        return false
      end

      amplify!(user)
      on_authentication_success(user, kind, credentials, authenticating_authority)
      user
    end

    ##
    # Allows an authority to unconditionally block access for a user.
    #
    # If an authority sometimes wishes to prevent authentication for a
    # user, even if some authority has indicated that he or she has
    # {#valid_credentials? valid credentials}, it can implement this
    # method and return true when appropriate.
    #
    # The composite behavior aggregates the responses for all
    # implementing authorities, returning true if any of them return
    # true.
    #
    # @param [Bcsec::User] user the user who will be declared
    #   authentic unless this method returns true.
    #
    # @return [Boolean] true to block access, false otherwise
    def veto?(user)
      poll(:veto?, user).detect { |result, authority| result }
    end

    ##
    # A callback which is invoked when {#valid_credentials?}
    # is about to return a new user.  It has no control over whether
    # authentication will proceed &mdash; it's just a notification.
    #
    # The composite behavior is to invoke the callback on all the
    # authorities which implement it.
    #
    # @param [Bcsec::User] user the user which has been authenticated.
    # @param [Symbol] kind the kind of credentials (the same value
    #   originally passed to {#valid_credentials?}).
    # @param [Array] credentials the actual credentials which were
    #   determined to be valid (the same value originally passed to
    #   {#valid_credentials?}).
    # @param [Object] authenticating_authority the (first) authority
    #   which determined that the credentials were valid.
    #
    # @return [void]
    def on_authentication_success(user, kind, credentials, authenticating_authority)
      @config.logger.info("User \"#{user.username}\" was successfully authenticated " <<
                          "by #{authenticating_authority.class}.")
      poll(:on_authentication_success, user, kind, credentials, authenticating_authority)
    end

    ##
    # A callback which is invoked when {#valid_credentials?}  is going
    # to return `false` or `nil`.  It has no control over whether
    # authentication will proceed &mdash; it's just a notification.
    #
    # The composite behavior is to invoke the callback on all the
    # authorities which implement it.
    #
    # @param [Bcsec::User,nil] user the user whose access is being
    #   denied.  This may be nil if the authentication failure happens
    #   before the credentials are mapped to a user.
    # @param [Symbol] kind the kind of credentials (the same value
    #   originally passed to {#valid_credentials?}).
    # @param [Array] credentials the actual credentials which were
    #   determined to be valid (the same value originally passed to
    #   {#valid_credentials?}).
    # @param [String] reason the reason why authentication failed,
    #   broadly speaking; e.g., `"invalid credentials"` or `"user vetoed
    #   by Pers"`.
    #
    # @return [void]
    def on_authentication_failure(user, kind, credentials, reason)
      @config.logger.info("Authentication attempt#{" by \"#{user.username}\"" if user} " <<
                          "failed: #{reason}.")
      poll(:on_authentication_failure, user, kind, credentials, reason)
    end

    ##
    # Fills in any information about the user which the authority
    # knows but which is not already present in the given object.
    # In addition to the simple attributes on {Bcsec::User}, this
    # method should fill in all available authorization information.
    #
    # The composite behavior is to invoke `amplify!` on each of the
    # configured {#authorities} in series, passing the given user to
    # each.
    #
    # @param [Bcsec::User] user the user to modify in-place.
    #
    # @return [Bcsec::User] the passed-in user
    #
    # @see Bcsec::User#merge!
    def amplify!(user)
      user.default_portal = @config.portal if @config.portal? && !user.default_portal
      poll(:amplify!, user)
      user
    end

    ##
    # Finds users matching the given criteria.  Criteria may either be
    # `String`s or `Hash`es.  If it's a single `String`, it is
    # interpreted as a username and this method will return an array
    # containing either a single user with that username or an empty
    # array.  If the criteria is a `Hash`, the behavior will be
    # authority-dependent.  However, all the attributes of
    # {Bcsec::User} are reserved parameter names &mdash; if an
    # authority interprets the value associated with a {Bcsec::User}
    # attribute name, it must be interpreted as an exact-match
    # criteria for that authority's understanding of that attribute
    # (whatever it is).
    #
    # If more than one criterion is provided, each value is treated
    # separately according to the description given above for a single
    # value.  The resulting array will contain each matching user
    # exactly once.  It will not be possible to determine from the
    # results alone which returned user matched which criterion.
    #
    # Examples:
    #
    #     authority.find_users("wakibbe") # => that single user, if
    #                                     #    the username is known
    #     authority.find_users(:first_name => 'Warren')
    #                                     # => all the users named
    #                                     #    Warren
    #     authority.find_users(
    #       :first_name => 'Warren', :last_name => 'Kibbe')
    #                                     # => all the users named
    #                                     #    Warren Kibbe
    #     authority.find_users(
    #       { :first_name => 'Warren' }, { :last_name => 'Kibbe' })
    #                                     # => all the users with
    #                                     #    first name Warren or
    #                                     #    last name Kibbe
    #
    # The composite behavior is to invoke `find_users` on all the
    # authorities which support it and merge the resulting lists.  Any
    # users with the same username are merged using
    # {Bcsec::User#merge!}.  Finally, all the users are {#amplify!
    # amplified}.
    #
    # This method will always return an array.
    #
    # @param [Array<Hash,#to_s>] criteria (see above)
    #
    # @return [Array<Bcsec::User>] the matching users
    def find_users(*criteria)
      poll(:find_users, *criteria).
        collect { |result, authority| result }.
        compact.
        inject([]) { |aggregate, users| merge_user_lists!(aggregate, users.compact) }.
        each { |user| amplify!(user) }
    end
    include Support::FindSoleUser

    protected

    def merge_user_lists!(target, new_users)
      new_users.each do |u|
        existing = target.find { |t| t.username == u.username }
        if existing
          existing.merge!(u)
        else
          target << u
        end
      end
      target
    end

    ##
    # Invokes the specified method with the specified arguments on all
    # the authorities which will respond to it.
    def poll(method, *args)
      authorities.select { |a|
        a.respond_to?(method)
      }.collect { |a|
        # adapter for old find_users signature.  Remove in 2.1.
        if method == :find_users && a.method(method).arity == 1 && args.size > 1
          Bcsec::Deprecation.notify(
            "Implement #{a.class}#find_users with a *splat as of 2.0.4.", "2.1")
          [a.send(method, args.first), a]
        else
          [a.send(method, *args), a]
        end
      }
    end
  end
end
