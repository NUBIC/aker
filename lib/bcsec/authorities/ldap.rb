require 'net/ldap'
require 'bcsec/authorities'

module Bcsec::Authorities
  ##
  # A generic authority for performing authentication and user lookup
  # via an LDAP server.  It authenticates username/password
  # combinations and fills in demographic information from the LDAP
  # record.  It also implements {#find_users find_users} to provide
  # searches separately from authentication.
  #
  # This authority supports multiple instances if you need to combine
  # the results from multiple LDAP servers in a single Bcsec
  # configuration. Setting up multiple instances either requires
  # directly constructing the instances (i.e., not using the `:ldap`
  # alias and having Bcsec construct them for you) or writing
  # separately constructable subclasses. The former makes sense for
  # one-off configurations while the latter is better for reuse. See
  # also {Configuration::Slice} for setting default parameters in
  # extensions and {Configuration#alias_authority} for giving pithy
  # names to authority subclasses.
  #
  # @example Configuring a single LDAP authority
  #    Bcsec.configure {
  #      ldap_parameters :server => "ldap.example.org"
  #      authority :ldap
  #    }
  #
  # @example Configuring multiple LDAP authorities via manual construction
  #    Bcsec.configure {
  #      hr_parameters :server => "hr.example.com", :port => 5003
  #      dept_parameters :server => "ldap.mydept.example.com"
  #
  #      hr_ldap = Bcsec::Authorities::Ldap.new(this, :hr)
  #      dept_ldap = Bcsec::Authorities::Ldap.new(this, :dept)
  #
  #      authorities hr_ldap, dept_ldap
  #    }
  #
  # @example Defining multiple LDAP authorities via subclassing
  #    # Not pictured: using a default slice and aliasing to make
  #    # these authorities look like built-in authorities.
  #
  #    class HrLdap < Bcsec::Authorities::Ldap
  #      def initialize(config); super config, :hr; end
  #    end
  #    class DeptLdap < Bcsec::Authorities::Ldap
  #      def initialize(config); super config, :dept; end
  #    end
  #
  #    Bcsec.configure {
  #      hr_parameters :server => "hr.example.com", :port => 5003
  #      dept_parameters :server => "ldap.mydept.example.com"
  #      authorities HrLdap, DeptLdap
  #    }
  #
  # @since 2.2.0
  # @author Rhett Sutphin
  class Ldap
    # Bidirectional mapping between LDAP attributes and Bcsec::User
    # attributes.  Only contains directly-mappable values.
    LDAP_TO_BCSEC_ATTRIBUTE_MAPPING = {
      :uid => :username,
      :sn => :last_name,
      :givenname => :first_name,
      :title => :title,
      :mail => :email,
      :telephonenumber => :business_phone,
      :facsimiletelephonenumber => :fax,
    }.collect { |ldap_attr, bcsec_attr|
      { :ldap => ldap_attr, :bcsec => bcsec_attr }
    }

    ##
    # Create a new instance.  (Unlike bcsec 1.x's `NetidAuthenticator`,
    # this class is not a singleton.)
    #
    # @param [Configuration, Hash] config the configuration for
    #   this instance.  If a hash, the parameters are extracted
    #   directly.  If a {Configuration}, the parameters are
    #   extracted using {Configuration#parameters_for
    #   parameters_for(name)} (where `name` is the name parameter to
    #   this constructor; default is `:ldap`).
    #
    # @option config [String] :server The hostname for the LDAP server
    #   (required)
    #
    # @option config [Integer] :port (636) The port to use to connect to the
    #  LDAP server
    #
    # @option config [Boolean] :use_tls (true) Whether the LDAP server
    #   uses TLS. Note that if you set this to false, you'll probably
    #   need to change the port as well.
    #
    # @option config [String] :user A username to use to bind to
    #   the server before searching or authenticating (optional)
    #
    # @option config [String] :password The password that goes with
    #   *:user* (optional; required if *:user* is specified)
    #
    # @param [Symbol] name the name for this authority. If you need to
    #   have multiple LDAP authorities in the same configuration,
    #   distinguish them by name.
    def initialize(config, name=:ldap)
      @config =
        case config
        when Bcsec::Configuration
          config.parameters_for(name)
        else
          config
        end
      validate_config!
    end

    ## Accessor for the configured server.
    # @return [String]
    def server
      @config[:server]
    end

    ## Accessor for the port to use in connecting to the server.
    # Defaults to 636.
    # @return [Integer]
    def port
      @config[:port] || 636
    end

    ## Accessor for the configured user.
    # @return [String]
    def user
      @config[:user]
    end

    ## Accessor for the configured password.
    # @return [String]
    def password
      @config[:password]
    end

    ##
    # Accessor for whether to use TLS.
    # @return [Boolean]
    def use_tls
      @config[:use_tls].nil? ? true : @config[:use_tls]
    end

    ##
    # @private (only exposed for testing)
    # @return [Hash]
    def ldap_parameters
      {
        :host => server, :port => port,
        :auth => if user
                   { :method => :simple, :username => user, :password => password }
                 else
                   { :method => :anonymous }
                 end,
        :encryption => (:simple_tls if use_tls)
      }
    end

    ##
    # Verifies a username and password using the configured NU LDAP
    # server.  Only supports the `:user` credential kind.  There must
    # be exactly two credentials.
    #
    # @return [User, nil, :unsupported] a complete user record
    #   if the credentials are valid, `nil` if they aren't valid, and
    #   `:unsupported` if the first parameter is anything other than
    #   `:user`
    def valid_credentials?(kind, *credentials)
      return :unsupported unless kind == :user

      username, password = credentials
      return nil unless password && !password.strip.empty?

      with_ldap do |ldap|
        result = find_by_criteria(ldap, :username => username)
        if result.size == 1
          return ldap.authentic?(one_value(result[0], :dn), password) ? create_user(result[0]) : nil
        else
          return nil
        end
      end
    end

    ##
    # Searches for and returns users matching the given criteria.  If
    # the criteria is a `String`, it is treated as a username.  If it
    # is a `Hash`, the keys are interpreted as {Bcsec::User} attribute
    # names. Those attributes which are directly mappable to LDAP
    # attributes will be used to build a filtered LDAP query.  If the
    # `Hash` contains no keys which are mappable to LDAP attribute
    # names, no query will be performed and an empty array will be
    # returned.
    #
    # @see Composite#find_users
    # @return [Array<User>]
    def find_users(*criteria)
      with_ldap do |ldap|
        result = find_by_criteria(ldap, *criteria)
        return result.collect { |r| create_user(r) }
      end
    end
    include Support::FindSoleUser

    protected

    def create_user(ldap_entry)
      Bcsec::User.new(one_value(ldap_entry, :uid)).tap do |u|
        # directly mappable attrs
        LDAP_TO_BCSEC_ATTRIBUTE_MAPPING.reject { |map| map[:bcsec] == :username }.collect { |map|
          [map[:ldap], :"#{map[:bcsec]}="]
        }.each do |ldap_attr, user_setter|
          u.send user_setter, one_value(ldap_entry, ldap_attr)
        end

        u.extend Bcsec::Ldap::UserExt
        u.ldap_attributes = ldap_entry
      end
    end

    def create_criteria_filter(criterion)
      case criterion
      when Hash
        criterion.collect { |bcsec_attribute, value|
          create_single_filter(bcsec_attribute.to_sym, value)
        }.compact.inject { |all, filter|
          all & filter
        }
      else
        create_criteria_filter(:username => criterion.to_s)
      end
    end

    def with_ldap
      # Net::LDAP.open leaks connections in 0.0.4, so do this instead
      ldap = Net::LDAP.new(ldap_parameters)
      yield ldap
    end

    def find_by_criteria(ldap, *criteria)
      filter = criteria.collect { |c| create_criteria_filter(c) }.inject { |a, f| a | f }
      return [] unless filter
      base = "dc=northwestern,dc=edu"
      ldap.search(:filter => filter, :base => base)
    end

    def one_value(ldap_entry, key)
      item = [*ldap_entry[key]].first
      item.nil? ? nil : item.dup
    end

    def validate_config!
      self.server or raise "The server parameter is required for ldap."
      if self.user.nil? ^ self.password.nil?
        raise "For ldap, both user and password are required if one is set."
      end
    end

    def create_single_filter(bcsec_attribute, value)
      ldap_attribute_map =
        LDAP_TO_BCSEC_ATTRIBUTE_MAPPING.detect { |map| map[:bcsec] == bcsec_attribute }
      if !value.nil? && ldap_attribute_map
        Net::LDAP::Filter.eq(ldap_attribute_map[:ldap].to_s, value)
      end
    end
  end
end

##
# Bcsec-specific extensions to net/ldap.
class Net::LDAP
  ##
  # Sugar for using LDAP bind to verify a password.
  #
  # @param dn [String] a full distinguished name
  # @param password [String] a password to check
  # @return [Boolean]
  def authentic?(dn, password)
    self.authenticate(dn, password)
    self.bind
  end
end
