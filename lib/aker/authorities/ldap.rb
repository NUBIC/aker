require 'net/ldap'
require 'aker/authorities'

module Aker::Authorities
  ##
  # A generic authority for performing authentication and user lookup
  # via an LDAP server.  It authenticates username/password
  # combinations and fills in demographic information from the LDAP
  # record.  It also implements {#find_users find_users} to provide
  # searches separately from authentication.
  #
  # This authority supports multiple instances if you need to combine
  # the results from multiple LDAP servers in a single Aker
  # configuration. Setting up multiple instances either requires
  # directly constructing the instances (i.e., not using the `:ldap`
  # alias and having Aker construct them for you) or writing
  # separately constructable subclasses. The former makes sense for
  # one-off configurations while the latter is better for reuse. See
  # also {Configuration::Slice} for setting default parameters in
  # extensions and {Configuration#alias_authority} for giving pithy
  # names to authority subclasses.
  #
  # @example Configuring a single LDAP authority
  #    Aker.configure {
  #      ldap_parameters :server => "ldap.example.org"
  #      authority :ldap
  #    }
  #
  # @example Configuring multiple LDAP authorities via manual construction
  #    Aker.configure {
  #      hr_parameters :server => "hr.example.com", :port => 5003
  #      dept_parameters :server => "ldap.mydept.example.com"
  #
  #      hr_ldap = Aker::Authorities::Ldap.new(this, :hr)
  #      dept_ldap = Aker::Authorities::Ldap.new(this, :dept)
  #
  #      authorities hr_ldap, dept_ldap
  #    }
  #
  # @example Defining multiple LDAP authorities via subclassing
  #    # Not pictured: using a default slice and aliasing to make
  #    # these authorities look like built-in authorities.
  #
  #    class HrLdap < Aker::Authorities::Ldap
  #      def initialize(config); super config, :hr; end
  #    end
  #    class DeptLdap < Aker::Authorities::Ldap
  #      def initialize(config); super config, :dept; end
  #    end
  #
  #    Aker.configure {
  #      hr_parameters :server => "hr.example.com", :port => 5003
  #      dept_parameters :server => "ldap.mydept.example.com"
  #      authorities HrLdap, DeptLdap
  #    }
  #
  # @since 2.2.0
  # @author Rhett Sutphin
  class Ldap
    ##
    # @see #attribute_map
    DEFAULT_ATTRIBUTE_MAP = {
      :uid => :username,
      :sn => :last_name,
      :givenname => :first_name,
      :title => :title,
      :mail => :email,
      :telephonenumber => :business_phone,
      :facsimiletelephonenumber => :fax,
    }.freeze

    ##
    # Create a new instance.
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
    # @option config [Hash<Symbol, Symbol>] :attribute_map Extensions
    #   and overrides for the LDAP-to-Aker user attribute
    #   mapping. See {#attribute_map} for details.
    #
    # @option config [Hash<Symbol, #call>] :attribute_processors See
    #   {#attribute_processors} for details.
    #
    # @option config [Hash<Symbol, Symbol>] :criteria_map See
    #   {#criteria_map} for details.
    #
    # @param [Symbol] name the name for this authority. If you need to
    #   have multiple LDAP authorities in the same configuration,
    #   distinguish them by name.
    def initialize(config, name=:ldap)
      @config =
        case config
        when Aker::Configuration
          config.parameters_for(name)
        else
          config
        end
      validate_config!
    end

    def config
      @config
    end
    protected :config

    ##
    # The configured server's hostname or other address.
    # @return [String]
    def server
      @config[:server]
    end

    ##
    # The port to use when connecting to the server.
    # Defaults to 636.
    # @return [Integer]
    def port
      @config[:port] || 636
    end

    ##
    # The user to bind as before searching or authenticating.
    # @return [String,nil]
    def user
      @config[:user]
    end

    ##
    # The password to use with {#user}.
    # @return [String,nil]
    def password
      @config[:password]
    end

    ##
    # Whether to use TLS when communicating with the server.
    # @return [Boolean]
    def use_tls
      @config[:use_tls].nil? ? true : @config[:use_tls]
    end

    ##
    # The mapping between attributes from the LDAP server and
    # {Aker::User} attributes. This mapping is used in two ways:
    #
    # * When returning users from the LDAP server, the first value for any
    #   mapped attribute is used as the value for that attribute in the
    #   user object.
    # * Aker user attributes in this map will be translated into LDAP
    #   attributes when doing a criteria query with {#find_users}.
    #
    # There is a default mapping which will be reasonable for many
    # cases. To extend it, provide the `:attribute_map` parameter when
    # constructing this authority.
    #
    # If this mapping is not reversible (i.e., each value is unique),
    # then the behavior of this authority is not defined. Each value
    # in this map must be a writable attribute on Aker::User.
    #
    # @example
    #   ldap.attribute_map # => { :givenname => :first_name }
    #   ldap.find_user('jmt123')
    #     # => The givenName attribute in the LDAP record will be
    #     #    mapped to Aker::User#first_name in the returned user
    #   ldap.find_users(:first_name => 'Jo')
    #     # => The LDAP server will be queried using givenName=Jo.
    #
    # @return [Hash<Symbol, Symbol>] the mapping from LDAP attribute
    #   to Aker user attribute.
    def attribute_map
      @attribute_map ||= DEFAULT_ATTRIBUTE_MAP.merge(@config[:attribute_map] || {})
    end

    ##
    # @return [Hash<Symbol, Symbol>] The reverse of {#attribute_map}.
    def reverse_attribute_map
      @reverse_attribute_map ||= attribute_map.inject({}) { |h, (k, v)| h[v] = k; h }
    end
    protected :reverse_attribute_map

    ##
    # A set of named procs which will be applied while creating a
    # {Aker::User} from an LDAP entry. The values in the map should
    # be procs. Each proc should accept three arguments:
    #
    # * The user being created from the LDAP entry.
    # * The full ldap entry. This is a hash-like object that allows
    #   you to retrieve LDAP attributes using their names in lower
    #   case. Values in the entry may be arrays or scalars. They may
    #   not be serializable, so before copying a value out you should
    #   be sure to dup it.
    # * A proc that allows you to safely extract a single value from
    #   the entry. The values returned from this proc are safe to set
    #   directly in the user.
    #
    # If there is an entry in this mapping whose key is the same as a
    # key in {#attribute_map}, the processor will be used instead of
    # the simple mapping implied by `attribute_map`.
    #
    # @example An example processor
    #   lambda { |user, entry, s|
    #     user.identifiers[:ssn] = s[:ssn]
    #   }
    #
    # @return [Hash<Symbol, #call>]
    def attribute_processors
      @attribute_processors ||= attribute_map_processors.merge(@config[:attribute_processors] || {})
    end

    def attribute_map_processors
      Hash[attribute_map.collect { |ldap, aker|
        [ldap, lambda { |user, entry, s| user.send("#{aker}=", s[ldap]) }]
      }]
    end
    private :attribute_map_processors

    ##
    # A mapping between attributes from the LDAP server and criteria
    # keys used in {#find_users}. This mapping will be used when
    # translating criteria hashes into LDAP queries. It is similar to
    # {#attribute_map} in that way, but there are two differences:
    #
    # * The mapping is [criteria key] => [LDAP attribute]. This is the
    #   reverse of `attribute_map`.
    # * The "criteria" in `attribute_map` have to be {Aker::User}
    #   attribute names. This map does not have that restriction.
    #
    # If a criterion appears both in this map and `attribute_map`, the
    # mapping in this map is used.
    #
    # @return [Hash<Symbol,Symbol>]
    def criteria_map
      @config[:criteria_map] || {}
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
    # is a `Hash`, the keys are interpreted as {Aker::User} attribute
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
      Aker::User.new(one_value(ldap_entry, :uid)).tap do |u|
        s = lambda { |k| one_value(ldap_entry, k) }
        attribute_processors.reject { |k, v| k == :username }.each do |k, processor|
          processor.call(u, ldap_entry, s)
        end

        u.extend Aker::Ldap::UserExt
        u.ldap_attributes = ldap_entry
      end
    end

    def create_criteria_filter(criterion)
      case criterion
      when Hash
        criterion.collect { |aker_attribute, value|
          create_single_filter(aker_attribute.to_sym, value)
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

    def create_single_filter(aker_attribute, value)
      ldap_attribute = criteria_map[aker_attribute] || reverse_attribute_map[aker_attribute]
      if !value.nil? && ldap_attribute
        Net::LDAP::Filter.eq(ldap_attribute.to_s, value)
      end
    end
  end
end

##
# Aker-specific extensions to net/ldap.
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
